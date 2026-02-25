import SwiftUI

struct ChildPlayerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlayerViewModel

    let book: BookDTO

    init(book: BookDTO) {
        self.book = book
        _viewModel = StateObject(wrappedValue: PlayerViewModel(apiClient: APIClient(tokenProvider: { nil })))
    }

    var body: some View {
        VStack(spacing: 0) {
            PlayerContainerView(player: viewModel.player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)

            VStack(spacing: 12) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(viewModel.isPlaying ? "Pause" : "Play") {
                        viewModel.togglePlayPause()
                    }
                    .buttonStyle(.borderedProminent)

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
            }
        }
        .navigationBarBackButtonHidden(true)
        .task(id: book.id) {
            if let childID = appViewModel.activeChild?.id {
                viewModel.rebindClient(appViewModel.apiClient)
                await viewModel.preparePlayback(for: book, childID: childID)
            }
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
    }
}
