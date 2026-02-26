import SwiftUI

struct ChildPlayerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlayerViewModel

    @State private var sliderValue: Double = 0
    @State private var isEditingSlider = false

    let book: BookDTO

    init(book: BookDTO) {
        self.book = book
        _viewModel = StateObject(wrappedValue: PlayerViewModel(apiClient: APIClient(tokenProvider: { nil })))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                PlayerContainerView(player: viewModel.player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)

                if viewModel.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading video...")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else if viewModel.isBuffering {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Buffering...")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            VStack(spacing: 12) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let resumedFrom = viewModel.resumedFromSeconds, resumedFrom > 0 {
                    Text("Resumed at \(formatTime(resumedFrom))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 6) {
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
                            if !editing {
                                viewModel.seek(to: sliderValue)
                            }
                        }
                    )

                    HStack {
                        Text(formatTime(viewModel.currentSeconds))
                        Spacer()
                        Text(formatTime(viewModel.durationSeconds))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.seekBy(deltaSeconds: -10)
                    } label: {
                        Text("-10s")
                    }
                    .buttonStyle(.bordered)

                    Button(viewModel.isPlaying ? "Pause" : "Play") {
                        viewModel.togglePlayPause()
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        viewModel.seekBy(deltaSeconds: 10)
                    } label: {
                        Text("+10s")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    Menu {
                        ForEach(viewModel.availableCaptions) { option in
                            Button {
                                viewModel.selectCaption(optionID: option.id)
                            } label: {
                                if viewModel.selectedCaptionOptionID == option.id {
                                    Label(option.label, systemImage: "checkmark")
                                } else {
                                    Text(option.label)
                                }
                            }
                        }
                    } label: {
                        Label("Captions", systemImage: "captions.bubble")
                    }
                    .buttonStyle(.bordered)

                    Button("Back to Library") {
                        viewModel.stopPlayback()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.systemBackground))

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.bottom, 10)
                    .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task(id: book.id) {
            if let childID = appViewModel.activeChild?.id {
                viewModel.rebindClient(appViewModel.apiClient)
                await viewModel.preparePlayback(for: book, childID: childID)
            }
        }
        .onReceive(viewModel.$currentSeconds) { seconds in
            guard !isEditingSlider else { return }
            sliderValue = Double(seconds)
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let clamped = max(totalSeconds, 0)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
