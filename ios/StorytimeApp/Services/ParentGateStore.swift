import CryptoKit
import Foundation

final class ParentGateStore {
    private let keychain = KeychainStore()
    private let pinHashKey = "parent_gate_pin_hash"

    private(set) var sessionExpiry: Date?

    func hasPIN() -> Bool {
        keychain.read(key: pinHashKey) != nil
    }

    func setPIN(_ pin: String) {
        let hash = SHA256.hash(data: Data(pin.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        keychain.save(hash, key: pinHashKey)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let savedHash = keychain.read(key: pinHashKey) else {
            return false
        }

        let hash = SHA256.hash(data: Data(pin.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        return hash == savedHash
    }

    func openSession() {
        sessionExpiry = Date().addingTimeInterval(AppConfig.parentGateSessionSeconds)
    }

    func sessionIsValid() -> Bool {
        guard let sessionExpiry else {
            return false
        }
        return sessionExpiry > Date()
    }

    func closeSession() {
        sessionExpiry = nil
    }
}
