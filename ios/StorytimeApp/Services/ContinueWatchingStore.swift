import Foundation

final class ContinueWatchingStore {
    struct Entry: Codable {
        let positionSeconds: Int
        let durationSeconds: Int
        let updatedAt: Date
    }

    static let shared = ContinueWatchingStore()
    static let didChangeNotification = Notification.Name("continueWatchingStoreDidChange")

    private let defaults: UserDefaults
    private let storageKey = "storytime.continue_watching.entries"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func entry(forBookID bookID: Int) -> Entry? {
        entries()[String(bookID)]
    }

    func resumePosition(forBookID bookID: Int) -> Int? {
        guard let entry = entry(forBookID: bookID), entry.positionSeconds > 0 else {
            return nil
        }
        return entry.positionSeconds
    }

    func progress(forBookID bookID: Int) -> Double? {
        guard let entry = entry(forBookID: bookID), entry.durationSeconds > 0 else {
            return nil
        }

        return min(max(Double(entry.positionSeconds) / Double(entry.durationSeconds), 0), 1)
    }

    func save(bookID: Int, positionSeconds: Int, durationSeconds: Int) {
        let normalizedPosition = max(positionSeconds, 0)
        let normalizedDuration = max(durationSeconds, 1)

        var current = entries()
        current[String(bookID)] = Entry(
            positionSeconds: normalizedPosition,
            durationSeconds: normalizedDuration,
            updatedAt: Date()
        )
        write(entries: current)
    }

    func clear(bookID: Int) {
        var current = entries()
        current.removeValue(forKey: String(bookID))
        write(entries: current)
    }

    private func entries() -> [String: Entry] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data)
        else {
            return [:]
        }

        return decoded
    }

    private func write(entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else {
            return
        }

        defaults.set(data, forKey: storageKey)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
