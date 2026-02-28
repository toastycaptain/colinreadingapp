import SwiftUI

struct ParentLibraryManagementView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        List {
            if appViewModel.libraryBooks.isEmpty {
                Text("No books assigned.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appViewModel.libraryBooks) { book in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.headline)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink("Open") {
                            ChildPlayerView(book: book)
                        }
                        .buttonStyle(.bordered)
                        Button("Remove", role: .destructive) {
                            Task {
                                await appViewModel.removeBookFromActiveChild(bookID: book.id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Child Library")
        .task {
            await appViewModel.refreshLibrary()
        }
    }
}
