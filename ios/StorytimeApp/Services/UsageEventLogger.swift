import Foundation
import UIKit

final class UsageEventLogger {
    private let apiClient: APIClient
    private let isoFormatter = ISO8601DateFormatter()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func logEvent(childID: Int, bookID: Int, eventType: String, positionSeconds: Int?) {
        Task {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let metadata = [
                "app_version": appVersion,
                "device_model": UIDevice.current.model,
            ]

            let event = UsageEventRequestDTO(
                childID: childID,
                bookID: bookID,
                eventType: eventType,
                positionSeconds: positionSeconds,
                occurredAt: isoFormatter.string(from: Date()),
                metadata: metadata
            )

            try? await apiClient.postUsageEvent(event)
        }
    }
}
