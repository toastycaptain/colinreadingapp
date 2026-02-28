import Foundation

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: () -> String?

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared, tokenProvider: @escaping () -> String?) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
    }

    func login(email: String, password: String) async throws -> AuthResponseDTO {
        try await send(path: "auth/login", method: "POST", body: ["email": email, "password": password], requiresAuth: false)
    }

    func register(email: String, password: String, consentAccepted: Bool, policyVersion: String) async throws -> AuthResponseDTO {
        let payload = RegisterRequestDTO(
            email: email,
            password: password,
            consentAccepted: consentAccepted,
            policyVersion: policyVersion
        )
        return try await send(
            path: "auth/register",
            method: "POST",
            body: payload,
            requiresAuth: false
        )
    }

    func logout() async throws {
        _ = try await sendEmpty(path: "auth/logout", method: "POST")
    }

    func forgotPassword(email: String, resetURL: String? = nil) async throws {
        var payload: [String: String] = ["email": email]
        if let resetURL {
            payload["reset_url"] = resetURL
        }
        _ = try await sendEmpty(path: "auth/password/forgot", method: "POST", body: payload, requiresAuth: false)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        _ = try await sendEmpty(
            path: "auth/password/reset",
            method: "POST",
            body: [
                "reset_password_token": token,
                "password": newPassword,
            ],
            requiresAuth: false
        )
    }

    func children() async throws -> [ChildProfileDTO] {
        try await send(path: "children", method: "GET")
    }

    func createChild(name: String) async throws -> ChildProfileDTO {
        try await send(path: "children", method: "POST", body: ["name": name])
    }

    func updateChild(id: Int, name: String) async throws -> ChildProfileDTO {
        try await send(path: "children/\(id)", method: "PATCH", body: ["name": name])
    }

    func catalogBooks(query: String? = nil, age: Int? = nil, category: String? = nil, publisherID: Int? = nil, page: Int = 1, perPage: Int = 20) async throws -> CatalogResponseDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("catalog/books"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "per_page", value: String(perPage))]
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if let age {
            queryItems.append(URLQueryItem(name: "age", value: String(age)))
        }
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let publisherID {
            queryItems.append(URLQueryItem(name: "publisher", value: String(publisherID)))
        }
        components.queryItems = queryItems

        return try await request(url: components.url!, method: "GET", body: Optional<String>.none)
    }

    func catalogBookDetail(bookID: Int) async throws -> BookDTO {
        try await send(path: "catalog/books/\(bookID)", method: "GET")
    }

    func catalogCategories() async throws -> [CatalogCategoryDTO] {
        let response: CatalogCategoriesResponseDTO = try await send(path: "catalog/categories", method: "GET")
        return response.data
    }

    func childLibrary(childID: Int) async throws -> [BookDTO] {
        try await send(path: "children/\(childID)/library", method: "GET")
    }

    func addBookToLibrary(childID: Int, bookID: Int) async throws {
        _ = try await sendEmpty(path: "children/\(childID)/library_items", method: "POST", body: ["book_id": bookID])
    }

    func removeBookFromLibrary(childID: Int, bookID: Int) async throws {
        _ = try await sendEmpty(path: "children/\(childID)/library_items/\(bookID)", method: "DELETE")
    }

    func createPlaybackSession(childID: Int, bookID: Int) async throws -> PlaybackSessionDTO {
        try await send(path: "children/\(childID)/playback_sessions", method: "POST", body: ["book_id": bookID])
    }

    func postUsageEvent(_ event: UsageEventRequestDTO) async throws {
        _ = try await sendEmpty(path: "usage_events", method: "POST", body: event)
    }

    private func send<T: Decodable, B: Encodable>(path: String, method: String, body: B? = nil, requiresAuth: Bool = true) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        return try await request(url: url, method: method, body: body, requiresAuth: requiresAuth)
    }

    private func send<T: Decodable>(path: String, method: String, requiresAuth: Bool = true) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        return try await request(url: url, method: method, body: Optional<EmptyBody>.none, requiresAuth: requiresAuth)
    }

    private func sendEmpty(path: String, method: String, requiresAuth: Bool = true) async throws -> Bool {
        let url = baseURL.appendingPathComponent(path)
        let _: EmptyResponse = try await request(url: url, method: method, body: Optional<EmptyBody>.none, requiresAuth: requiresAuth)
        return true
    }

    private func sendEmpty<B: Encodable>(path: String, method: String, body: B, requiresAuth: Bool = true) async throws -> Bool {
        let url = baseURL.appendingPathComponent(path)
        let _: EmptyResponse = try await request(url: url, method: method, body: body, requiresAuth: requiresAuth)
        return true
    }

    private func request<T: Decodable, B: Encodable>(url: URL, method: String, body: B?, requiresAuth: Bool = true) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let jwt = tokenProvider() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if (200...299).contains(httpResponse.statusCode) {
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
                return try decoder.decode(T.self, from: data)
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            if let apiError = try? decoder.decode(ErrorResponseDTO.self, from: data) {
                throw APIError.server(code: apiError.error.code, message: apiError.error.message)
            }

            throw APIError.transport("Request failed with status \(httpResponse.statusCode)")
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private struct EmptyBody: Encodable {}
    private struct EmptyResponse: Decodable {}
    private struct RegisterRequestDTO: Encodable {
        let email: String
        let password: String
        let consentAccepted: Bool
        let policyVersion: String

        enum CodingKeys: String, CodingKey {
            case email
            case password
            case consentAccepted = "consent_accepted"
            case policyVersion = "policy_version"
        }
    }
}
