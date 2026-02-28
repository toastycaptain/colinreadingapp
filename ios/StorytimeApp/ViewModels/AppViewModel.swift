import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum Mode {
        case child
        case parent
    }

    @Published var currentUser: UserDTO?
    @Published var jwt: String?
    @Published var children: [ChildProfileDTO] = []
    @Published var activeChild: ChildProfileDTO?
    @Published var libraryBooks: [BookDTO] = []
    @Published var catalogBooks: [BookDTO] = []
    @Published var catalogCategories: [CatalogCategoryDTO] = []
    @Published var catalogPagination: CatalogResponseDTO.PaginationDTO?
    @Published var catalogIsLoading = false
    @Published var catalogHasMore = false
    @Published var mode: Mode = .child
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showParentGate = false

    private let sessionStore = AuthSessionStore()
    private let gateStore = ParentGateStore()

    private let catalogPerPage = 20
    private var catalogQuery: String?
    private var catalogCategory: String?
    private var catalogAge: Int?
    private var nextCatalogPage = 1

    lazy var apiClient = APIClient(tokenProvider: { [weak self] in
        self?.jwt
    })

    func bootstrap() async {
        jwt = sessionStore.loadJWT()
        guard jwt != nil else {
            configureDemoExperience()
            return
        }
        await refreshChildren()
    }

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let auth = try await apiClient.login(email: email, password: password)
            currentUser = auth.user
            jwt = auth.jwt
            sessionStore.saveJWT(auth.jwt)
            await refreshChildren()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func register(email: String, password: String, consentAccepted: Bool, policyVersion: String = AppConfig.privacyPolicyVersion) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let auth = try await apiClient.register(
                email: email,
                password: password,
                consentAccepted: consentAccepted,
                policyVersion: policyVersion
            )
            currentUser = auth.user
            jwt = auth.jwt
            sessionStore.saveJWT(auth.jwt)
            await refreshChildren()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        jwt = nil
        currentUser = nil
        children = []
        activeChild = nil
        libraryBooks = []
        catalogBooks = []
        catalogCategories = []
        catalogPagination = nil
        catalogHasMore = false
        mode = .child
        showParentGate = false
        gateStore.closeSession()
        sessionStore.clear()
        configureDemoExperience()
    }

    func refreshChildren() async {
        guard jwt != nil else {
            configureDemoExperience()
            return
        }

        do {
            children = try await apiClient.children()
            if activeChild == nil {
                activeChild = children.first
            } else if let activeID = activeChild?.id {
                activeChild = children.first(where: { $0.id == activeID })
            }

            if activeChild != nil {
                await refreshLibrary()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createChild(name: String) async {
        do {
            let child = try await apiClient.createChild(name: name)
            children.append(child)
            activeChild = child
            mode = .child
            await refreshLibrary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectChild(_ child: ChildProfileDTO) async {
        activeChild = child
        mode = .child
        await refreshLibrary()
    }

    func refreshLibrary() async {
        guard jwt != nil else {
            libraryBooks = [DemoContent.howToBook]
            return
        }

        guard let childID = activeChild?.id else {
            libraryBooks = []
            return
        }

        do {
            libraryBooks = try await apiClient.childLibrary(childID: childID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCatalogCategories() async {
        guard jwt != nil else {
            catalogCategories = [DemoContent.howToCategory]
            return
        }

        do {
            catalogCategories = try await apiClient.catalogCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchCatalog(query: String) async {
        await searchCatalog(query: query, category: nil, age: nil, reset: true)
    }

    func searchCatalog(query: String, category: String?, age: Int?, reset: Bool) async {
        guard jwt != nil else {
            runDemoCatalogSearch(query: query, category: category, age: age, reset: reset)
            return
        }

        if reset {
            catalogQuery = query
            catalogCategory = category
            catalogAge = age
            nextCatalogPage = 1
            catalogHasMore = false
            catalogPagination = nil
            catalogBooks = []
        }

        guard !catalogIsLoading else { return }
        guard reset || catalogHasMore || nextCatalogPage == 1 else { return }

        catalogIsLoading = true
        defer { catalogIsLoading = false }

        do {
            let response = try await apiClient.catalogBooks(
                query: catalogQuery,
                age: catalogAge,
                category: catalogCategory,
                page: nextCatalogPage,
                perPage: catalogPerPage
            )

            if reset {
                catalogBooks = response.data
            } else {
                let existingIDs = Set(catalogBooks.map(\.id))
                let newRows = response.data.filter { !existingIDs.contains($0.id) }
                catalogBooks.append(contentsOf: newRows)
            }

            catalogPagination = response.pagination
            catalogHasMore = catalogBooks.count < response.pagination.totalCount
            if catalogHasMore {
                nextCatalogPage += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreCatalog() async {
        await searchCatalog(
            query: catalogQuery ?? "",
            category: catalogCategory,
            age: catalogAge,
            reset: false
        )
    }

    func addBookToActiveChild(bookID: Int) async {
        guard jwt != nil else {
            if !libraryBooks.contains(where: { $0.id == DemoContent.howToBook.id }) {
                libraryBooks.insert(DemoContent.howToBook, at: 0)
            }
            return
        }

        guard let childID = activeChild?.id else { return }

        do {
            try await apiClient.addBookToLibrary(childID: childID, bookID: bookID)
            await refreshLibrary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBookFromActiveChild(bookID: Int) async {
        guard jwt != nil else {
            if bookID == DemoContent.howToBook.id {
                errorMessage = "The How To guide is pinned for demo mode."
                return
            }
            libraryBooks.removeAll(where: { $0.id == bookID })
            return
        }

        guard let childID = activeChild?.id else { return }

        do {
            try await apiClient.removeBookFromLibrary(childID: childID, bookID: bookID)
            await refreshLibrary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestParentMode() {
        if gateStore.sessionIsValid() {
            mode = .parent
            return
        }

        showParentGate = true
    }

    func setParentPIN(_ pin: String) {
        gateStore.setPIN(pin)
        gateStore.openSession()
        showParentGate = false
        mode = .parent
    }

    func verifyParentPIN(_ pin: String) -> Bool {
        let isValid = gateStore.verifyPIN(pin)
        if isValid {
            gateStore.openSession()
            showParentGate = false
            mode = .parent
        }
        return isValid
    }

    func hasParentPIN() -> Bool {
        gateStore.hasPIN()
    }

    func exitParentMode() {
        mode = .child
        showParentGate = false
    }

    private func configureDemoExperience() {
        currentUser = UserDTO(id: -1, email: "demo@storytime.local", role: "parent")
        children = [DemoContent.demoChild]

        if activeChild == nil || children.contains(where: { $0.id == activeChild?.id }) == false {
            activeChild = DemoContent.demoChild
        }

        libraryBooks = [DemoContent.howToBook]
        catalogBooks = [DemoContent.howToBook]
        catalogCategories = [DemoContent.howToCategory]
        catalogPagination = CatalogResponseDTO.PaginationDTO(page: 1, perPage: catalogPerPage, totalCount: 1)
        catalogHasMore = false
        nextCatalogPage = 1
        mode = .child
    }

    private func runDemoCatalogSearch(query: String, category: String?, age: Int?, reset: Bool) {
        if reset {
            catalogQuery = query
            catalogCategory = category
            catalogAge = age
            nextCatalogPage = 1
            catalogHasMore = false
            catalogPagination = nil
            catalogBooks = []
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var books = [DemoContent.howToBook]

        if let category, !category.isEmpty {
            books = books.filter { ($0.category ?? "").caseInsensitiveCompare(category) == .orderedSame }
        }

        if let age {
            books = books.filter { book in
                let minAge = book.ageMin ?? 0
                let maxAge = book.ageMax ?? 99
                return age >= minAge && age <= maxAge
            }
        }

        if !normalizedQuery.isEmpty {
            books = books.filter { book in
                let haystack = [book.title, book.author, book.description ?? ""].joined(separator: " ").lowercased()
                return haystack.contains(normalizedQuery)
            }
        }

        catalogBooks = books
        catalogPagination = CatalogResponseDTO.PaginationDTO(
            page: 1,
            perPage: catalogPerPage,
            totalCount: books.count
        )
        catalogHasMore = false
        nextCatalogPage = 1
    }
}
