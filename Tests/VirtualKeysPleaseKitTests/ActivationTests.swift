import Foundation
import Testing
import os
@testable import VirtualKeysPleaseKit

private func bytes(_ hex: String) -> Data {
    Data(stride(from: 0, to: hex.count, by: 2).map {
        let start = hex.index(hex.startIndex, offsetBy: $0)
        return UInt8(hex[start..<hex.index(start, offsetBy: 2)], radix: 16)!
    })
}

@Test("AES-256 CBC matches NIST SP 800-38A, without padding")
func nistVector() throws {
    let key = bytes("603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4")
    let iv = bytes("000102030405060708090a0b0c0d0e0f")
    let plain = bytes("6bc1bee22e409f96e93d7e117393172a")
    let cipher = bytes("f58c4c04d6e5f1ba779eabfb5f7bfbd6")
    #expect(try ActivationCrypto.crypt(plain, key: key, iv: iv, encrypt: true) == cipher)
    #expect(try ActivationCrypto.crypt(cipher, key: key, iv: iv, encrypt: false) == plain)
}

@Test("Enabling preserves unrelated feature expiries and repeated use does not write")
func preserveFeatures() throws {
    let key = Data(repeating: 7, count: 32)
    let before = try ActivationRecord(now: 1_700_000_000, expires: ["other.feature": 2_000_000_000,
                                                                   "vsd.lock": 1_700_000_001]).encode(key: key)
    let change = try ActivationChange.prepare(previous: before, key: key, now: 1_800_000_000)
    let replacement = try #require(change.replacement)
    let after = try ActivationRecord.decode(replacement, key: key)
    #expect(after.expires["other.feature"] == 2_000_000_000)
    #expect(after.expires["vsd.lock"] == ActivationChange.expiry)
    #expect(after.now == 1_800_000_000)
    let again = try ActivationChange.prepare(previous: change.replacement, key: key, now: 1_800_000_001)
    #expect(again.alreadyEnabled)
    #expect(again.replacement == change.replacement)
}

@Test("Malformed, foreign and future-format records require a safe outcome")
func invalidRecords() throws {
    let key = Data(repeating: 4, count: 32)
    #expect(throws: KeysError.unreadableActivation) {
        try ActivationChange.prepare(previous: "garbage", key: key, now: 1_800_000_000)
    }
    let foreign = try ActivationRecord(now: 1, expires: [:]).encode(key: Data(repeating: 5, count: 32))
    #expect(throws: KeysError.unreadableActivation) {
        try ActivationChange.prepare(previous: foreign, key: key, now: 1_800_000_000)
    }
    let reset = try ActivationChange.prepare(previous: foreign, key: key, now: 1_800_000_000, allowReset: true)
    let resetValue = try #require(reset.replacement)
    #expect(try ActivationRecord.decode(resetValue, key: key).expires["vsd.lock"] == ActivationChange.expiry)
    let iv = Data(repeating: 1, count: 16)
    var clear = Data("{\"now\":1,\"expires\":{},\"newFormat\":true}".utf8)
    clear.append(contentsOf: repeatElement(UInt8(0), count: (16 - clear.count % 16) % 16))
    let future = (iv + (try ActivationCrypto.crypt(clear, key: key, iv: iv, encrypt: true))).base64EncodedString()
    #expect(throws: KeysError.unexpectedRecord) {
        try ActivationChange.prepare(previous: future, key: key, now: 1_800_000_000, allowReset: true)
    }
}

@Test("A clock rollback repairs the record timestamp instead of falsely reporting success")
func clockRollback() throws {
    let key = Data(repeating: 6, count: 32)
    let prior = try ActivationRecord(now: 1_900_000_000, expires: ["vsd.lock": ActivationChange.expiry]).encode(key: key)
    let change = try ActivationChange.prepare(previous: prior, key: key, now: 1_800_000_000)
    #expect(!change.alreadyEnabled)
    let replacement = try #require(change.replacement)
    #expect(try ActivationRecord.decode(replacement, key: key).now == 1_800_000_000)
}

@Test("Recognition accepts compatible new binaries and rejects a changed constant")
func methodRecognition() throws {
    let salt = Data((0..<256).map { UInt8($0) })
    let recognizer = MethodRecognizer(prefix: Data(salt.prefix(8)), fingerprint: ActivationCrypto.digest(salt))
    let markers = Data("FeatureUnlockData\0ESDFeatureUnlockStore\0ESDBootstrap_FeatureUnlocker\0UiSDUnlockDuration\0".utf8)
    let fixture = Data(repeating: 0x80, count: 37) + markers + salt
    #expect(try recognizer.salt(in: fixture) == salt)
    var corrupt = fixture
    corrupt[corrupt.endIndex - 1] ^= 1
    #expect(throws: KeysError.changedMethod) { try recognizer.salt(in: corrupt) }
    #expect(throws: KeysError.changedMethod) { try recognizer.salt(in: Data(salt)) }
}

private final class MemoryPreference: ActivationPreference {
    let value = OSAllocatedUnfairLock<String?>(initialState: nil)
    func read() throws -> String? { value.withLock { $0 } }
    func write(_ newValue: String?) throws { value.withLock { $0 = newValue } }
}

@Test("A durable backup precedes mutation; restore preserves later independent changes")
func transactionAndRestore() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let repository = BackupRepository(directory: folder)
    let store = MemoryPreference()
    let key = Data(repeating: 2, count: 32)
    let change = try ActivationChange.prepare(previous: nil, key: key, now: 1_800_000_000)
    let saved = try repository.commit(change, to: store, appVersion: "fixture", binaryDigest: "fixture")
    let backup = try #require(saved)
    #expect(FileManager.default.fileExists(atPath: backup.path))
    #expect(try store.read() == change.replacement)
    try store.write("a later independent change")
    #expect(throws: KeysError.laterChange) { try repository.restore(to: store) }
    #expect(try store.read() == "a later independent change")
    try store.write(change.replacement)
    try repository.restore(to: store)
    #expect(try store.read() == nil)
}

@Test("A concurrent setting change aborts before creating a backup or writing")
func concurrentChange() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let repository = BackupRepository(directory: folder)
    let store = MemoryPreference()
    let change = try ActivationChange.prepare(previous: nil, key: Data(repeating: 9, count: 32), now: 1_800_000_000)
    try store.write("another writer")
    #expect(throws: KeysError.changedDuringOperation) {
        try repository.commit(change, to: store, appVersion: "fixture", binaryDigest: "fixture")
    }
    #expect(!FileManager.default.fileExists(atPath: folder.path))
    #expect(try store.read() == "another writer")
}
