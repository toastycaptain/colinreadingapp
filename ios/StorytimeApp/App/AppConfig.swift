import Foundation

enum AppConfig {
    static let apiBaseURL = URL(string: ProcessInfo.processInfo.environment["STORYTIME_API_BASE_URL"] ?? "http://localhost:3000/api/v1")!
    static let parentGateSessionSeconds: TimeInterval = 300
    static let heartbeatIntervalSeconds: TimeInterval = 45
}
