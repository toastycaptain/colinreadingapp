import Foundation

final class AuthSessionStore {
    private let keychain = KeychainStore()
    private let jwtKey = "jwt"

    func saveJWT(_ token: String) {
        keychain.save(token, key: jwtKey)
    }

    func loadJWT() -> String? {
        keychain.read(key: jwtKey)
    }

    func clear() {
        keychain.delete(key: jwtKey)
    }
}
