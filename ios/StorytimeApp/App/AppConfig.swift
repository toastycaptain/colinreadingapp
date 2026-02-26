import Foundation

enum AppConfig {
    static let apiBaseURL = URL(
        string: ProcessInfo.processInfo.environment["STORYTIME_API_BASE_URL"]
            ?? bundleValue("STORYTIME_API_BASE_URL")
            ?? "http://localhost:3000/api/v1"
    )!

    static let privacyPolicyURL = URL(
        string: ProcessInfo.processInfo.environment["STORYTIME_PRIVACY_POLICY_URL"]
            ?? bundleValue("STORYTIME_PRIVACY_POLICY_URL")
            ?? "https://www.example.com/privacy"
    )!

    static let termsURL = URL(
        string: ProcessInfo.processInfo.environment["STORYTIME_TERMS_URL"]
            ?? bundleValue("STORYTIME_TERMS_URL")
            ?? "https://www.example.com/terms"
    )!

    static let privacyPolicyVersion = ProcessInfo.processInfo.environment["STORYTIME_PRIVACY_POLICY_VERSION"]
        ?? bundleValue("STORYTIME_PRIVACY_POLICY_VERSION")
        ?? "2026-02"

    static let parentGateSessionSeconds: TimeInterval = 300
    static let heartbeatIntervalSeconds: TimeInterval = 45

    private static func bundleValue(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
