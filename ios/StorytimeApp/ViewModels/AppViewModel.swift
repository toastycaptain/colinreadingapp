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
    @Published var mode: Mode = .child
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showParentGate = false

    private let sessionStore = AuthSessionStore()
    private let gateStore = ParentGateStore()

    lazy var apiClient = APIClient(tokenProvider: { [weak self] in
        self?.jwt
    })

    func bootstrap() async {
        jwt = sessionStore.loadJWT()
        guard jwt != nil else { return }
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

    func register(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let auth = try await apiClient.register(email: email, password: password)
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
        mode = .child
        showParentGate = false
        gateStore.closeSession()
        sessionStore.clear()
    }

    func refreshChildren() async {
        guard jwt != nil else { return }

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

    func searchCatalog(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            catalogBooks = []
            return
        }

        do {
            let response = try await apiClient.catalogBooks(query: query)
            catalogBooks = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addBookToActiveChild(bookID: Int) async {
        guard let childID = activeChild?.id else { return }

        do {
            try await apiClient.addBookToLibrary(childID: childID, bookID: bookID)
            await refreshLibrary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBookFromActiveChild(bookID: Int) async {
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
}
