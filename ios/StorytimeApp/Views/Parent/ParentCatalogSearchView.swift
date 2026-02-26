import SwiftUI

struct ParentCatalogSearchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    @State private var query = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedAge: Int? = nil

    private let ageOptions = Array(2...12)

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search books", text: $query)
                    .textFieldStyle(.roundedBorder)

                Button("Search") {
                    Task { await runCatalogSearch(reset: true) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(title: "All")

                    ForEach(appViewModel.catalogCategories, id: \.category) { row in
                        categoryChip(title: "\(row.category) (\(row.bookCount))") {
                            row.category
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Menu {
                    Button("All ages") { selectedAge = nil }
                    ForEach(ageOptions, id: \.self) { age in
                        Button("Age \(age)") { selectedAge = age }
                    }
                } label: {
                    Label(selectedAgeText, systemImage: "figure.and.child.holdinghands")
                }
                .buttonStyle(.bordered)

                Spacer()

                if appViewModel.catalogIsLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal)

            if appViewModel.catalogBooks.isEmpty, !appViewModel.catalogIsLoading {
                Spacer()
                Text("Search or browse by category")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(appViewModel.catalogBooks) { book in
                        NavigationLink {
                            ParentBookDetailView(bookID: book.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.title)
                                    .font(.headline)
                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let category = book.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

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
                    }

                    if appViewModel.catalogHasMore {
                        HStack {
                            Spacer()
                            Button("Load More") {
                                Task {
                                    await appViewModel.loadMoreCatalog()
                                }
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Catalog")
        .task {
            await appViewModel.loadCatalogCategories()
            await runCatalogSearch(reset: true)
        }
        .onChange(of: selectedAge) { _ in
            Task { await runCatalogSearch(reset: true) }
        }
    }

    private func categoryChip(title: String, categoryValue: (() -> String?)? = nil) -> some View {
        let resolvedCategory = categoryValue?() ?? "All"
        let isSelected = selectedCategory == resolvedCategory

        return Button(title) {
            selectedCategory = resolvedCategory
            Task { await runCatalogSearch(reset: true) }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private var selectedAgeText: String {
        if let selectedAge {
            return "Age \(selectedAge)"
        }
        return "All ages"
    }

    private func runCatalogSearch(reset: Bool) async {
        let category = selectedCategory == "All" ? nil : selectedCategory
        await appViewModel.searchCatalog(
            query: query,
            category: category,
            age: selectedAge,
            reset: reset
        )
    }
}
