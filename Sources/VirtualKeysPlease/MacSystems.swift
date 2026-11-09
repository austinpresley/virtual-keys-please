import AppKit
import IOKit
import Security
import VirtualKeysPleaseKit

nonisolated struct InstalledTarget: Sendable {
    let url: URL
    let version: String
    let binaryDigest: String
    let salt: Data
}

actor TargetInspector {
    func inspect(_ selected: URL) throws -> InstalledTarget {
        let url = selected.resolvingSymlinksInPath().standardizedFileURL
        guard url.pathExtension.lowercased() == "app", let bundle = Bundle(url: url),
              bundle.bundleIdentifier == "com.elgato.StreamDeck",
              let executable = bundle.executableURL,
              executable.resolvingSymlinksInPath().path.hasPrefix(url.path + "/Contents/MacOS/") else {
            throw KeysError.notStreamDeck
        }
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let identity = "anchor apple generic and identifier \"com.elgato.StreamDeck\" and certificate leaf[subject.OU] = \"Y93VXCB8Q5\""
        guard SecRequirementCreateWithString(identity as CFString, [], &requirement) == errSecSuccess,
              let requirement else { throw KeysError.untrustedApp }
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures), requirement) == errSecSuccess else {
            throw KeysError.untrustedApp
        }
        var information: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let info = information as? [String: Any],
              info[kSecCodeInfoTeamIdentifier as String] as? String == "Y93VXCB8Q5",
              info[kSecCodeInfoIdentifier as String] as? String == "com.elgato.StreamDeck" else {
            throw KeysError.untrustedApp
        }
        let size = try executable.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size > 0 && size <= 536_870_912 else { throw KeysError.changedMethod }
        let binary = try Data(contentsOf: executable, options: [.mappedIfSafe])
        let salt = try MethodRecognizer.current.salt(in: binary)
        return InstalledTarget(url: url,
                    version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown version",
                    binaryDigest: ActivationCrypto.digest(binary), salt: salt)
    }
}

nonisolated struct MacActivationPreference: ActivationPreference {
    let domain: String
    private let key = "FeatureUnlockData"

    init(domain: String = "com.elgato.StreamDeck") { self.domain = domain }

    func read() throws -> String? {
        guard CFPreferencesAppSynchronize(domain as CFString) else { throw KeysError.writeFailed }
        guard let value = CFPreferencesCopyAppValue(key as CFString, domain as CFString) else { return nil }
        guard let string = value as? String else { throw KeysError.unexpectedRecord }
        return string
    }

    func write(_ value: String?) throws {
        CFPreferencesSetAppValue(key as CFString, value.map { $0 as CFString }, domain as CFString)
        guard CFPreferencesAppSynchronize(domain as CFString) else { throw KeysError.writeFailed }
    }
}

nonisolated enum ThisMac {
    static func activationKey(salt: Data) throws -> Data {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/")
        guard entry != 0 else { throw KeysError.invalidCrypto }
        defer { IOObjectRelease(entry) }
        guard let uuid = IORegistryEntryCreateCFProperty(entry, "IOPlatformUUID" as CFString,
                    kCFAllocatorDefault, 0)?.takeRetainedValue() as? String, !uuid.isEmpty else {
            throw KeysError.invalidCrypto
        }
        return ActivationCrypto.key(salt: salt, platformUUID: uuid)
    }

    static var backupDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Virtual Keys Please/Backups", isDirectory: true)
    }
}

actor ActivationWorker {
    func apply(to target: InstalledTarget, allowReset: Bool) throws -> Bool {
        let store = MacActivationPreference()
        let key = try ThisMac.activationKey(salt: target.salt)
        let change = try ActivationChange.prepare(previous: store.read(), key: key,
                          now: Int64(Date().timeIntervalSince1970), allowReset: allowReset)
        let repository = BackupRepository(directory: ThisMac.backupDirectory)
        _ = try repository.commit(change, to: store, appVersion: target.version, binaryDigest: target.binaryDigest)
        return change.alreadyEnabled
    }

    func restore() throws {
        try BackupRepository(directory: ThisMac.backupDirectory).restore(to: MacActivationPreference())
    }

    func hasBackup() -> Bool {
        (try? BackupRepository(directory: ThisMac.backupDirectory).latest()) != nil
    }
}

enum StreamDeckLifecycle {
    static func installedURL() -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.elgato.StreamDeck")
    }

    static func stop(_ target: InstalledTarget) async throws -> Bool {
        let copies = NSRunningApplication.runningApplications(withBundleIdentifier: "com.elgato.StreamDeck")
        guard copies.allSatisfy({ $0.bundleURL?.resolvingSymlinksInPath().standardizedFileURL == target.url }) else {
            throw KeysError.otherCopyRunning
        }
        for copy in copies { _ = copy.terminate() }
        for _ in 0..<100 {
            if copies.allSatisfy(\.isTerminated) { return !copies.isEmpty }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw KeysError.stillRunning
    }

    static func open(_ target: InstalledTarget, activate: Bool = true) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = activate
        _ = try await NSWorkspace.shared.openApplication(at: target.url, configuration: configuration)
    }
}
