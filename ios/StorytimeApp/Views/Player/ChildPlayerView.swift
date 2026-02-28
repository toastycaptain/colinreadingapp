import SwiftUI

struct ChildPlayerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlayerViewModel

    @State private var sliderValue: Double = 0
    @State private var isEditingSlider = false
    @State private var volumeLevel: Double = 1.0
    @State private var controlsVisible = true
    @State private var controlsHideTask: Task<Void, Never>?

    let book: BookDTO

    init(book: BookDTO) {
        self.book = book
        _viewModel = StateObject(wrappedValue: PlayerViewModel(apiClient: APIClient(tokenProvider: { nil })))
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Color.black
                    .ignoresSafeArea()

                PlayerContainerView(player: viewModel.player)
                    .frame(
                        width: landscapeVideoWidth(for: geometry.size, isLandscape: isLandscape),
                        height: geometry.size.height
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
                    .clipped()

                if isLandscape {
                    landscapeFrameOverlay(in: geometry.size)
                } else {
                    portraitControls
                        .opacity(controlsVisible ? 1 : 0)
                        .allowsHitTesting(controlsVisible)
                }

                loadingOverlay
            }
            .background(.black)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        revealControls()
                    }
                    .onEnded { _ in
                        showControlsTemporarily()
                    }
            )
            .overlay(alignment: .bottom) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.bottom, 12)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .task(id: book.id) {
            let childID = appViewModel.activeChild?.id ?? DemoContent.demoChild.id
            viewModel.rebindClient(appViewModel.apiClient)
            await viewModel.preparePlayback(for: book, childID: childID)
            volumeLevel = Double(viewModel.player.volume)
            showControlsTemporarily()
        }
        .onReceive(viewModel.$currentSeconds) { seconds in
            guard !isEditingSlider else { return }
            sliderValue = Double(seconds)
        }
        .onDisappear {
            controlsHideTask?.cancel()
            viewModel.stopPlayback()
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let clamped = max(totalSeconds, 0)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progressSlider: some View {
        Slider(
            value: Binding(
                get: {
                    if isEditingSlider {
                        return sliderValue
                    }
                    return Double(viewModel.currentSeconds)
                },
                set: { newValue in
                    sliderValue = newValue
                }
            ),
            in: 0...Double(max(viewModel.durationSeconds, 1)),
            onEditingChanged: { editing in
                isEditingSlider = editing
                showControlsTemporarily()
                if !editing {
                    viewModel.seek(to: sliderValue)
                }
            }
        )
        .tint(.white)
    }

    private var timeRow: some View {
        HStack {
            Text(formatTime(viewModel.currentSeconds))
            Spacer()
            Text(formatTime(viewModel.durationSeconds))
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.white.opacity(0.9))
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                statusOverlay("Loading video...")
            } else if viewModel.isBuffering {
                statusOverlay("Buffering...")
            }
        }
    }

    private func statusOverlay(_ text: String) -> some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(text)
                .font(.footnote)
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color.black.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var portraitControls: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    libraryButton
                }

                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                progressSlider
                timeRow

                controlButtonsRow
            }
            .padding(16)
            .background(Color.black.opacity(0.55))
        }
    }

    private func landscapeFrameOverlay(in size: CGSize) -> some View {
        let frameInset = max(18, size.height * 0.035)

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 4)
                .padding(frameInset)

            Group {
                VStack {
                    HStack {
                        Spacer()
                        libraryButton
                    }
                    .padding(.top, frameInset + 6)
                    .padding(.trailing, frameInset + 6)

                    Spacer()

                    VStack(spacing: 10) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        progressSlider
                        timeRow
                        controlButtonsRow
                    }
                    .padding(.horizontal, frameInset + 28)
                    .padding(.bottom, frameInset + 16)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        volumeBar(length: size.height * 0.5)
                            .padding(.trailing, frameInset + 6)
                    }
                    Spacer()
                }
            }
            .opacity(controlsVisible ? 1 : 0)
            .allowsHitTesting(controlsVisible)
        }
    }

    private var libraryButton: some View {
        Button {
            showControlsTemporarily()
            viewModel.stopPlayback()
            dismiss()
        } label: {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var controlButtonsRow: some View {
        HStack(spacing: 28) {
            seekIconButton(symbol: "arrow.counterclockwise.circle", label: "-10") {
                showControlsTemporarily()
                viewModel.seekBy(deltaSeconds: -10)
            }

            Button {
                showControlsTemporarily()
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 66, height: 66)
                    .background(Circle().fill(Color.white.opacity(0.95)))
            }
            .buttonStyle(.plain)

            seekIconButton(symbol: "arrow.clockwise.circle", label: "+10") {
                showControlsTemporarily()
                viewModel.seekBy(deltaSeconds: 10)
            }
        }
    }

    private func seekIconButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image(systemName: symbol)
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(.white.opacity(0.95))

                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
    }

    private func volumeBar(length: CGFloat) -> some View {
        Slider(
            value: Binding(
                get: { volumeLevel },
                set: { newValue in
                    volumeLevel = newValue
                    viewModel.player.volume = Float(newValue)
                    showControlsTemporarily()
                }
            ),
            in: 0...1
        )
        .tint(.white)
        .frame(width: length)
        .rotationEffect(.degrees(-90))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func revealControls() {
        guard !controlsVisible else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            controlsVisible = true
        }
    }

    private func showControlsTemporarily() {
        revealControls()
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    controlsVisible = false
                }
            }
        }
    }

    private func landscapeVideoWidth(for size: CGSize, isLandscape: Bool) -> CGFloat {
        guard isLandscape else { return size.width }

        // Keep playback within a typical mobile landscape viewport.
        let maxLandscapeAspect: CGFloat = 2.2
        return min(size.width, size.height * maxLandscapeAspect)
    }
}
