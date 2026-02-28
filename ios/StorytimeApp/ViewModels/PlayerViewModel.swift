import AVFoundation
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    struct CaptionOption: Identifiable, Hashable {
        static let offID = "off"

        let id: String
        let label: String
    }

    @Published var player = AVPlayer()
    @Published var errorMessage: String?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var isBuffering = false
    @Published var currentSeconds = 0
    @Published var durationSeconds = 0
    @Published var availableCaptions: [CaptionOption] = [CaptionOption(id: CaptionOption.offID, label: "Off")]
    @Published var selectedCaptionOptionID: String = CaptionOption.offID
    @Published var resumedFromSeconds: Int?

    private var apiClient: APIClient
    private var usageLogger: UsageEventLogger
    private let continueWatchingStore: ContinueWatchingStore

    private var currentChildID: Int?
    private var currentBook: BookDTO?
    private var heartbeatTimer: Timer?
    private var periodicTimeObserver: Any?
    private var notificationObservers: [NSObjectProtocol] = []
    private var itemStatusObservation: NSKeyValueObservation?
    private var hasRetriedAfterFailure = false
    private var lastPersistedAt = Date.distantPast

    private var captionOptionMap: [String: AVMediaSelectionOption] = [:]

    init(apiClient: APIClient, continueWatchingStore: ContinueWatchingStore = .shared) {
        self.apiClient = apiClient
        self.usageLogger = UsageEventLogger(apiClient: apiClient)
        self.continueWatchingStore = continueWatchingStore
    }

    func preparePlayback(for book: BookDTO, childID: Int) async {
        currentBook = book
        currentChildID = childID
        errorMessage = nil
        hasRetriedAfterFailure = false
        resumedFromSeconds = continueWatchingStore.resumePosition(forBookID: book.id)

        await requestSessionAndPlay(resumeFromSeconds: resumedFromSeconds, eventType: "play_start")
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

    func seek(to seconds: Double) {
        let target = max(0, min(seconds, Double(max(durationSeconds, currentSeconds + 1))))
        let seekTime = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: seekTime)
        currentSeconds = Int(target)
        persistContinueWatchingState(force: true)
    }

    func seekBy(deltaSeconds: Int) {
        seek(to: Double(currentSeconds + deltaSeconds))
    }

    func selectCaption(optionID: String) {
        guard let item = player.currentItem,
              let mediaGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        else {
            return
        }

        if optionID == CaptionOption.offID {
            item.select(nil, in: mediaGroup)
            selectedCaptionOptionID = CaptionOption.offID
            return
        }

        guard let option = captionOptionMap[optionID] else {
            return
        }

        item.select(option, in: mediaGroup)
        selectedCaptionOptionID = optionID
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

        persistContinueWatchingState(force: true)
        cleanup()
    }

    func rebindClient(_ apiClient: APIClient) {
        self.apiClient = apiClient
        self.usageLogger = UsageEventLogger(apiClient: apiClient)
    }

    private func requestSessionAndPlay(resumeFromSeconds: Int?, eventType: String) async {
        guard let childID = currentChildID, let book = currentBook else { return }

        isLoading = true
        errorMessage = nil

        if book.id == DemoContent.howToBook.id {
            playLocalDemoBook(book: book, childID: childID, resumeFromSeconds: resumeFromSeconds, eventType: eventType)
            return
        }

        do {
            let session = try await apiClient.createPlaybackSession(childID: childID, bookID: book.id)
            let playbackURL = try buildPlaybackURL(from: session)

            let item = AVPlayerItem(url: playbackURL)
            player.replaceCurrentItem(with: item)
            observePlayerItem(item, resumeFromSeconds: resumeFromSeconds)
            observeTimeUpdates()

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
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func playLocalDemoBook(book: BookDTO, childID: Int, resumeFromSeconds: Int?, eventType: String) {
        let item = AVPlayerItem(url: DemoContent.howToPlaybackURL)
        player.replaceCurrentItem(with: item)
        observePlayerItem(item, resumeFromSeconds: resumeFromSeconds)
        observeTimeUpdates()

        player.play()
        isPlaying = true

        usageLogger.logEvent(
            childID: childID,
            bookID: book.id,
            eventType: eventType,
            positionSeconds: resumeFromSeconds
        )

        startHeartbeatIfNeeded()
    }

    private func observePlayerItem(_ item: AVPlayerItem, resumeFromSeconds: Int?) {
        itemStatusObservation?.invalidate()
        itemStatusObservation = item.observe(\AVPlayerItem.status, options: [.initial, .new]) { [weak self] observedItem, _ in
            Task { @MainActor in
                guard let self else { return }

                switch observedItem.status {
                case .readyToPlay:
                    let duration = observedItem.duration.seconds
                    if duration.isFinite {
                        self.durationSeconds = max(Int(duration), 0)
                    }

                    self.configureCaptionOptions(for: observedItem)

                    if let resumeFromSeconds, resumeFromSeconds > 0 {
                        let seekTime = CMTime(seconds: Double(resumeFromSeconds), preferredTimescale: 600)
                        observedItem.seek(to: seekTime)
                        self.currentSeconds = resumeFromSeconds
                    }

                    self.isLoading = false
                case .failed:
                    self.isLoading = false
                    self.errorMessage = observedItem.error?.localizedDescription ?? "Playback item failed"
                case .unknown:
                    self.isLoading = true
                @unknown default:
                    self.isLoading = false
                }
            }
        }

        let didEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self, let childID = self.currentChildID, let bookID = self.currentBook?.id else { return }
            self.isPlaying = false
            self.currentSeconds = self.durationSeconds
            self.usageLogger.logEvent(
                childID: childID,
                bookID: bookID,
                eventType: "play_end",
                positionSeconds: self.currentPositionSeconds
            )
            self.continueWatchingStore.clear(bookID: bookID)
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
            self.currentSeconds = self.currentPositionSeconds

            let duration = self.player.currentItem?.duration.seconds ?? 0
            if duration.isFinite {
                self.durationSeconds = max(Int(duration), self.durationSeconds)
            }

            self.isPlaying = self.player.timeControlStatus == .playing
            self.isBuffering = !self.isLoading && self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            self.persistContinueWatchingState(force: false)
        }
    }

    private func refreshSessionAfterFailure() async {
        guard !hasRetriedAfterFailure else {
            errorMessage = "Playback failed after retry. Please try again."
            return
        }

        hasRetriedAfterFailure = true
        let resumePosition = currentPositionSeconds
        await requestSessionAndPlay(resumeFromSeconds: resumePosition, eventType: "resume")
    }

    private func configureCaptionOptions(for item: AVPlayerItem) {
        captionOptionMap = [:]
        availableCaptions = [CaptionOption(id: CaptionOption.offID, label: "Off")]
        selectedCaptionOptionID = CaptionOption.offID

        guard let mediaGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return
        }

        let options = mediaGroup.options.enumerated().map { index, option -> CaptionOption in
            let optionID = "legible_\(index)"
            captionOptionMap[optionID] = option
            return CaptionOption(id: optionID, label: option.displayName)
        }

        availableCaptions += options

        if let selected = item.currentMediaSelection.selectedMediaOption(in: mediaGroup),
           let selectedID = captionOptionMap.first(where: { $0.value == selected })?.key {
            selectedCaptionOptionID = selectedID
        }
    }

    private func buildPlaybackURL(from session: PlaybackSessionDTO) throws -> URL {
        guard var components = URLComponents(string: session.playbackHlsURL) else {
            throw APIError.transport("Invalid playback URL")
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "token", value: session.playbackToken))
        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.transport("Invalid playback URL")
        }

        return url
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

    private func persistContinueWatchingState(force: Bool) {
        guard let bookID = currentBook?.id else { return }
        let now = Date()

        if !force && now.timeIntervalSince(lastPersistedAt) < 5 {
            return
        }

        let position = currentPositionSeconds
        let duration = max(durationSeconds, 1)
        let completion = Double(position) / Double(duration)

        if completion >= 0.95 {
            continueWatchingStore.clear(bookID: bookID)
        } else if position >= 15 {
            continueWatchingStore.save(
                bookID: bookID,
                positionSeconds: position,
                durationSeconds: duration
            )
        }

        lastPersistedAt = now
    }

    private func cleanup() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        if let periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
            self.periodicTimeObserver = nil
        }

        itemStatusObservation?.invalidate()
        itemStatusObservation = nil

        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()

        player.pause()
        player.replaceCurrentItem(with: nil)

        isPlaying = false
        isLoading = false
        isBuffering = false
        currentSeconds = 0
        durationSeconds = 0
        availableCaptions = [CaptionOption(id: CaptionOption.offID, label: "Off")]
        selectedCaptionOptionID = CaptionOption.offID
        captionOptionMap = [:]
    }
}
