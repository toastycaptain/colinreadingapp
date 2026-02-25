import AVFoundation
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var player = AVPlayer()
    @Published var errorMessage: String?
    @Published var isPlaying = false

    private var apiClient: APIClient
    private var usageLogger: UsageEventLogger

    private var currentChildID: Int?
    private var currentBook: BookDTO?
    private var heartbeatTimer: Timer?
    private var periodicTimeObserver: Any?
    private var notificationObservers: [NSObjectProtocol] = []

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.usageLogger = UsageEventLogger(apiClient: apiClient)
    }

    deinit {
        cleanup()
    }

    func preparePlayback(for book: BookDTO, childID: Int) async {
        currentBook = book
        currentChildID = childID
        errorMessage = nil

        await requestSessionAndPlay(resumeFromSeconds: nil, eventType: "play_start")
    }

    func togglePlayPause() {
        guard let childID = currentChildID, let bookID = currentBook?.id else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "pause",
                positionSeconds: currentPositionSeconds
            )
        } else {
            player.play()
            isPlaying = true
            usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "resume",
                positionSeconds: currentPositionSeconds
            )
        }
    }

    func stopPlayback() {
        if let childID = currentChildID, let bookID = currentBook?.id {
            usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "play_end",
                positionSeconds: currentPositionSeconds
            )
        }

        cleanup()
    }

    func rebindClient(_ apiClient: APIClient) {
        self.apiClient = apiClient
        self.usageLogger = UsageEventLogger(apiClient: apiClient)
    }

    private func requestSessionAndPlay(resumeFromSeconds: Int?, eventType: String) async {
        guard let childID = currentChildID, let book = currentBook else { return }

        do {
            let session = try await apiClient.createPlaybackSession(childID: childID, bookID: book.id)
            CookieInstaller.install(session.cookies)

            guard let manifestURL = URL(string: session.playbackManifestURL) else {
                throw APIError.transport("Invalid manifest URL")
            }

            let item = AVPlayerItem(url: manifestURL)
            player.replaceCurrentItem(with: item)
            observePlayerItem(item)
            observeTimeUpdates()

            if let resumeFromSeconds {
                let seekTime = CMTime(seconds: Double(resumeFromSeconds), preferredTimescale: 600)
                player.seek(to: seekTime)
            }

            player.play()
            isPlaying = true

            usageLogger.logEvent(
                childID: childID,
                bookID: book.id,
                eventType: eventType,
                positionSeconds: resumeFromSeconds
            )

            startHeartbeatIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        let didEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self, let childID = self.currentChildID, let bookID = self.currentBook?.id else { return }
            self.isPlaying = false
            self.usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "play_end",
                positionSeconds: self.currentPositionSeconds
            )
        }

        let failedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.refreshSessionAfterFailure()
            }
        }

        notificationObservers.append(contentsOf: [didEndObserver, failedObserver])
    }

    private func observeTimeUpdates() {
        if let periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
        }

        periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = self.player.timeControlStatus == .playing
        }
    }

    private func refreshSessionAfterFailure() async {
        let resumePosition = currentPositionSeconds
        await requestSessionAndPlay(resumeFromSeconds: resumePosition, eventType: "resume")
    }

    private var currentPositionSeconds: Int {
        Int(player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0)
    }

    private func startHeartbeatIfNeeded() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.heartbeatIntervalSeconds, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying,
                  let childID = self.currentChildID,
                  let bookID = self.currentBook?.id
            else {
                return
            }

            self.usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "heartbeat",
                positionSeconds: self.currentPositionSeconds
            )
        }
    }

    private func cleanup() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        if let periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
            self.periodicTimeObserver = nil
        }

        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
    }
}
