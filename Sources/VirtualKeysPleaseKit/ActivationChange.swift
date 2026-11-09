import Foundation

public protocol ActivationPreference: Sendable {
    func read() throws -> String?
    func write(_ value: String?) throws
}

public struct PreparedChange: Sendable {
    public let previous: String?
    public let replacement: String?
    public let alreadyEnabled: Bool
}

public enum ActivationChange {
    public static let expiry: Int64 = 4_102_444_800 // 2100-01-01, within the native microsecond clock's range.

    public static func prepare(previous: String?, key: Data, now: Int64,
                               allowReset: Bool = false) throws -> PreparedChange {
        var record = ActivationRecord(now: now, expires: [:])
        if let previous, !previous.isEmpty {
            do { record = try ActivationRecord.decode(previous, key: key) }
            catch KeysError.unreadableActivation where allowReset { }
        }
        if (record.expires["vsd.lock"] ?? 0) >= expiry && record.now <= now {
            return PreparedChange(previous: previous, replacement: previous, alreadyEnabled: true)
        }
        record.now = now
        record.expires["vsd.lock"] = expiry
        let encoded = try record.encode(key: key)
        guard try ActivationRecord.decode(encoded, key: key) == record else { throw KeysError.invalidCrypto }
        return PreparedChange(previous: previous, replacement: encoded, alreadyEnabled: false)
    }

    public static func valueDigest(_ value: String?) -> String {
        ActivationCrypto.digest(Data((value.map { "string:" + $0 } ?? "absent").utf8))
    }
}

public struct ChangeBackup: Codable, Sendable, Equatable {
    public let schema: Int
    public let created: Date
    public let appVersion: String
    public let binaryDigest: String
    public let previousValue: String?
    public let appliedDigest: String
}

public struct BackupRepository: Sendable {
    public let directory: URL

    public init(directory: URL) { self.directory = directory }

    public func commit(_ change: PreparedChange, to store: any ActivationPreference,
                       appVersion: String, binaryDigest: String, at date: Date = Date()) throws -> URL? {
        guard !change.alreadyEnabled else { return nil }
        guard try store.read() == change.previous else { throw KeysError.changedDuringOperation }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        let backup = ChangeBackup(schema: 1, created: date, appVersion: appVersion,
                                  binaryDigest: binaryDigest, previousValue: change.previous,
                                  appliedDigest: ActivationChange.valueDigest(change.replacement))
        let url = directory.appendingPathComponent("activation-\(UUID().uuidString).plist")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        guard !FileManager.default.fileExists(atPath: url.path) else { throw KeysError.writeFailed }
        try encoder.encode(backup).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        guard try PropertyListDecoder().decode(ChangeBackup.self, from: Data(contentsOf: url)) == backup else {
            throw KeysError.writeFailed
        }
        // A verified backup must exist before the first preference write.
        guard try store.read() == change.previous else { throw KeysError.changedDuringOperation }
        do {
            try store.write(change.replacement)
            guard try store.read() == change.replacement else { throw KeysError.writeFailed }
        } catch {
            if (try? store.read()) == change.replacement { try? store.write(change.previous) }
            throw error
        }
        return url
    }

    public func latest() throws -> (URL, ChangeBackup) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory,
                      includingPropertiesForKeys: nil)) ?? []
        let backups = files.filter { $0.pathExtension == "plist" }.compactMap { url -> (URL, ChangeBackup)? in
            guard let data = try? Data(contentsOf: url),
                  let backup = try? PropertyListDecoder().decode(ChangeBackup.self, from: data),
                  backup.schema == 1 else { return nil }
            return (url, backup)
        }
        guard let result = backups.max(by: { $0.1.created < $1.1.created }) else { throw KeysError.noBackup }
        return result
    }

    public func restore(to store: any ActivationPreference) throws {
        let (_, backup) = try latest()
        guard ActivationChange.valueDigest(try store.read()) == backup.appliedDigest else {
            throw KeysError.laterChange
        }
        try store.write(backup.previousValue)
        guard try store.read() == backup.previousValue else { throw KeysError.writeFailed }
    }
}
