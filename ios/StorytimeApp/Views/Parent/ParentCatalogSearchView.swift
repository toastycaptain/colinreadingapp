import SwiftUI

struct ParentCatalogSearchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var query = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search books", text: $query)
                    .textFieldStyle(.roundedBorder)

                Button("Search") {
                    Task { await appViewModel.searchCatalog(query: query) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if appViewModel.catalogBooks.isEmpty {
                Spacer()
                Text("Search to find books")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(appViewModel.catalogBooks) { book in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title)
                            .font(.headline)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Add to Child Library") {
                            Task {
                                await appViewModel.addBookToActiveChild(bookID: book.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Catalog")
    }
}
