import AppKit
import VirtualKeysPleaseKit

enum SelfCheck {
    static var requested: Bool {
        ProcessInfo.processInfo.arguments.contains("--selftest") || ProcessInfo.processInfo.arguments.contains("--inspect")
    }

    static func runIfRequested() -> Bool {
        guard requested else { return false }
        Task {
            do {
                if let index = CommandLine.arguments.firstIndex(of: "--inspect"), CommandLine.arguments.indices.contains(index + 1) {
                    let target = try await TargetInspector().inspect(URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                    let value = try MacActivationPreference().read()
                    let record = try value.map { try ActivationRecord.decode($0, key: ThisMac.activationKey(salt: target.salt)) }
                    print("PASS official Stream Deck \(target.version), compatible activation method")
                    print("Virtual keys expiry: \(record?.expires["vsd.lock"].map(String.init) ?? "not activated")")
                } else {
                    try isolatedPreferenceCheck()
                }
                NSApp.terminate(nil)
            } catch {
                FileHandle.standardError.write(Data("FAIL \(error.localizedDescription)\n".utf8))
                exit(1)
            }
        }
        return true
    }

    private static func isolatedPreferenceCheck() throws {
        let domain = "com.apresley.virtualkeysplease.selftest.\(UUID().uuidString)"
        let store = MacActivationPreference(domain: domain)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VKP-selftest-\(UUID().uuidString)")
        defer {
            try? store.write(nil)
            try? FileManager.default.removeItem(at: folder)
        }
        let key = Data(repeating: 3, count: 32)
        let change = try ActivationChange.prepare(previous: nil, key: key, now: 1_800_000_000)
        let repository = BackupRepository(directory: folder)
        _ = try repository.commit(change, to: store, appVersion: "isolated fixture", binaryDigest: "fixture")
        guard let applied = try store.read(),
              try ActivationRecord.decode(applied, key: key).expires["vsd.lock"] == ActivationChange.expiry else {
            throw KeysError.writeFailed
        }
        print("PASS isolated macOS preference write and readback")
        try repository.restore(to: store)
        guard try store.read() == nil else { throw KeysError.writeFailed }
        print("PASS exact activation-only restore")
        for symbol in ["app.badge.checkmark", "sparkle", "arrow.uturn.backward"] {
            guard NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil else {
                throw CocoaError(.featureUnsupported)
            }
        }
        print("PASS system symbols")
    }
}
