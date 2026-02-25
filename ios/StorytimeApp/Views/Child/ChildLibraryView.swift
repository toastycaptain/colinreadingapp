import SwiftUI

struct ChildLibraryView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

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
        }
    }
}
