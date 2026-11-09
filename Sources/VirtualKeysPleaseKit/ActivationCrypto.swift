import CryptoKit
import Foundation
import Security
import VKPCrypto

public enum KeysError: LocalizedError, Equatable, Sendable {
    case notStreamDeck, untrustedApp, changedMethod, unreadableActivation
    case unexpectedRecord, changedDuringOperation, writeFailed, noBackup, laterChange
    case invalidCrypto, stillRunning, otherCopyRunning

    public var errorDescription: String? {
        switch self {
        case .notStreamDeck: "That isn't the Elgato Stream Deck app. Drop Stream Deck itself here."
        case .untrustedApp: "This copy of Stream Deck couldn't be verified. Choose the official Elgato app."
        case .changedMethod: "This version uses a method I don't recognize yet. Nothing was changed."
        case .unreadableActivation: "The saved activation can't be read on this Mac. It may belong to another Mac or a different version."
        case .unexpectedRecord: "The activation format has changed. Nothing was changed."
        case .changedDuringOperation: "Stream Deck changed its setting while I was checking. Try once more."
        case .writeFailed: "macOS didn't save the activation change. The previous setting was kept where possible."
        case .noBackup: "There's no change from this app to restore yet."
        case .laterChange: "Stream Deck has changed this setting since my last visit. I kept your newer setting."
        case .invalidCrypto: "The activation record couldn't be prepared. Nothing was changed."
        case .stillRunning: "Stream Deck is still running. Finish its Quit dialog, or quit it yourself, then try again."
        case .otherCopyRunning: "Another copy of Stream Deck is open. Quit it before using this one."
        }
    }
}

public enum ActivationCrypto {
    public static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func key(salt: Data, platformUUID: String) -> Data {
        Data(SHA256.hash(data: salt + Data(platformUUID.utf8)))
    }

    public static func randomIV() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw KeysError.invalidCrypto
        }
        return Data(bytes)
    }

    /// The installed application's record format uses AES-256-CBC and zero padding.
    public static func crypt(_ input: Data, key: Data, iv: Data, encrypt: Bool) throws -> Data {
        guard key.count == 32, iv.count == 16, !input.isEmpty, input.count % 16 == 0 else {
            throw KeysError.invalidCrypto
        }
        var output = [UInt8](repeating: 0, count: input.count + 16)
        var moved = 0
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                input.withUnsafeBytes { inputBytes in
                    vkp_aes_cbc(encrypt ? 1 : 0,
                                keyBytes.bindMemory(to: UInt8.self).baseAddress!,
                                ivBytes.bindMemory(to: UInt8.self).baseAddress!,
                                inputBytes.bindMemory(to: UInt8.self).baseAddress!, input.count,
                                &output, output.count, &moved)
                }
            }
        }
        guard status == 0 else { throw KeysError.invalidCrypto }
        return Data(output.prefix(moved))
    }
}

public struct ActivationRecord: Codable, Equatable, Sendable {
    public var now: Int64
    public var expires: [String: Int64]

    public init(now: Int64, expires: [String: Int64]) {
        self.now = now
        self.expires = expires
    }

    public static func decode(_ value: String, key: Data) throws -> Self {
        guard value.utf8.count <= 1_048_576,
              let data = Data(base64Encoded: value), data.count >= 32 else {
            throw KeysError.unreadableActivation
        }
        var clear: Data
        do { clear = try ActivationCrypto.crypt(Data(data.dropFirst(16)), key: key,
                                               iv: Data(data.prefix(16)), encrypt: false) }
        catch { throw KeysError.unreadableActivation }
        while clear.last == 0 { clear.removeLast() }
        guard let object = try? JSONSerialization.jsonObject(with: clear) as? [String: Any] else {
            throw KeysError.unreadableActivation
        }
        guard Set(object.keys) == ["now", "expires"] else { throw KeysError.unexpectedRecord }
        guard let record = try? JSONDecoder().decode(Self.self, from: clear),
              record.now >= 0,
              record.expires.values.allSatisfy({ $0 >= 0 && $0 <= Int64.max / 1_000_000 }) else {
            throw KeysError.unexpectedRecord
        }
        return record
    }

    public func encode(key: Data, iv: Data? = nil) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var clear = try encoder.encode(self)
        clear.append(contentsOf: repeatElement(UInt8(0), count: (16 - clear.count % 16) % 16))
        let iv = try iv ?? ActivationCrypto.randomIV()
        return (iv + (try ActivationCrypto.crypt(clear, key: key, iv: iv, encrypt: true))).base64EncodedString()
    }
}
