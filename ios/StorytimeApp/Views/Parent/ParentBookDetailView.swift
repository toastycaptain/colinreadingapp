import SwiftUI

struct ParentBookDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    let bookID: Int

    @State private var book: BookDTO?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading details...")
                    .padding(.top, 40)
            } else if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            } else if let book {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text(book.title)
                        .font(.title3.weight(.bold))

                    Text("by \(book.author)")
                        .foregroundStyle(.secondary)

                    if let category = book.category {
                        Label(category, systemImage: "tag")
                            .font(.subheadline)
                    }

                    if let ageMin = book.ageMin, let ageMax = book.ageMax {
                        Label("Ages \(ageMin)-\(ageMax)", systemImage: "figure.and.child.holdinghands")
                            .font(.subheadline)
                    }

                    if let duration = book.videoAsset?.durationSeconds {
                        Label("Video length: \(formatDuration(duration))", systemImage: "clock")
                            .font(.subheadline)
                    }

                    if let publisher = book.publisher?.name {
                        Label(publisher, systemImage: "building.2")
                            .font(.subheadline)
                    }

                    if let description = book.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Button("Add to Child Library") {
                        Task {
                            await appViewModel.addBookToActiveChild(bookID: book.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetails()
        }
    }

    private func loadDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            book = try await appViewModel.apiClient.catalogBookDetail(bookID: bookID)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}
