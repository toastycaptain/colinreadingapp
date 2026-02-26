import SwiftUI

struct ChildLibraryView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    @State private var continueProgressByBookID: [Int: Double] = [:]
    @State private var continuePositionByBookID: [Int: Int] = [:]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if appViewModel.libraryBooks.isEmpty {
                VStack(spacing: 12) {
                    Text("Your library is empty")
                        .font(.headline)
                    Text("Ask a parent to add stories in Parent Mode.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(appViewModel.libraryBooks) { book in
                            NavigationLink {
                                ChildPlayerView(book: book)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.2))
                                    }
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    Text(book.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)

                                    Text(book.author)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    if let progress = continueProgressByBookID[book.id], progress > 0 {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ProgressView(value: progress)
                                            Text("Continue at \(formatTime(continuePositionByBookID[book.id] ?? 0))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(appViewModel.activeChild?.name ?? "Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Parent") {
                    appViewModel.requestParentMode()
                }
            }
        }
        .task {
            await appViewModel.refreshLibrary()
            reloadContinueWatchingState()
        }
        .onReceive(NotificationCenter.default.publisher(for: ContinueWatchingStore.didChangeNotification)) { _ in
            reloadContinueWatchingState()
        }
        .onChange(of: appViewModel.libraryBooks) { _ in
            reloadContinueWatchingState()
        }
    }

    private func reloadContinueWatchingState() {
        var progressMap: [Int: Double] = [:]
        var positionMap: [Int: Int] = [:]

        for book in appViewModel.libraryBooks {
            if let progress = ContinueWatchingStore.shared.progress(forBookID: book.id), progress > 0 {
                progressMap[book.id] = progress
            }

            if let position = ContinueWatchingStore.shared.resumePosition(forBookID: book.id), position > 0 {
                positionMap[book.id] = position
            }
        }

        continueProgressByBookID = progressMap
        continuePositionByBookID = positionMap
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let clamped = max(totalSeconds, 0)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
