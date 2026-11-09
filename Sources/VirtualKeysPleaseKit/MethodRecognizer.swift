import Foundation

public struct MethodRecognizer: Sendable {
    // These identify a public constant in the installed binary, not a user's key.
    // The complete salt and machine-derived key are never bundled or logged.
    public static let current = MethodRecognizer(
        prefix: Data([0xa5, 0xef, 0x0d, 0x37, 0xa1, 0x2e, 0x47, 0xa7]),
        fingerprint: "3fb3543d5a64dd071417c8a2244d21e368ac5a6f8549b1a86a548c95c77cb9e5"
    )

    let prefix: Data
    let fingerprint: String

    public init(prefix: Data, fingerprint: String) {
        self.prefix = prefix
        self.fingerprint = fingerprint
    }

    public func salt(in binary: Data) throws -> Data {
        guard binary.count <= 536_870_912, !prefix.isEmpty,
              ["FeatureUnlockData", "ESDFeatureUnlockStore", "ESDBootstrap_FeatureUnlocker", "UiSDUnlockDuration"]
                .allSatisfy({ binary.range(of: Data(($0 + "\0").utf8)) != nil }) else {
            throw KeysError.changedMethod
        }
        var start = binary.startIndex
        var matches = 0
        while start < binary.endIndex,
              let range = binary.range(of: prefix, in: start..<binary.endIndex) {
            matches += 1
            guard matches <= 32 else { throw KeysError.changedMethod }
            let end = range.lowerBound + 256
            if end <= binary.endIndex {
                let candidate = Data(binary[range.lowerBound..<end])
                if ActivationCrypto.digest(candidate) == fingerprint { return candidate }
            }
            start = range.lowerBound + 1
        }
        throw KeysError.changedMethod
    }
}
