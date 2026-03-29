import Foundation

final class NetworkClient: @unchecked Sendable {
    private let baseURL: String
    private let refreshBaseURL: String
    private let tokenStore: AuthTokenStore
    private let session: URLSession

    /// - Parameters:
    ///   - baseURL: The service URL (core/optimization/ordering).
    ///   - refreshBaseURL: Always the core service URL for token refresh. Defaults to baseURL.
    init(baseURL: String, refreshBaseURL: String? = nil, tokenStore: AuthTokenStore) {
        self.baseURL = baseURL
        self.refreshBaseURL = refreshBaseURL ?? baseURL
        self.tokenStore = tokenStore
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Public API

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let req = buildRequest(for: endpoint)
        let (data, response) = try await performRequest(req)
        guard let http = response as? HTTPURLResponse else { throw AppError.networkError }

        if http.statusCode == 401 {
            try await refresh()
            let retried = buildRequest(for: endpoint)
            let (retryData, retryResponse) = try await performRequest(retried)
            guard let retryHttp = retryResponse as? HTTPURLResponse else { throw AppError.networkError }
            if retryHttp.statusCode == 401 {
                handleSessionExpiry()
                throw AppError.unauthorized
            }
            return try decode(retryData, statusCode: retryHttp.statusCode)
        }

        return try decode(data, statusCode: http.statusCode)
    }

    func requestMultipart<T: Decodable>(
        _ endpoint: APIEndpoint,
        fields: [String: String],
        file: MultipartFile
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = makeMultipartBody(boundary: boundary, fields: fields, file: file)
        let req = buildMultipartRequest(for: endpoint, boundary: boundary, body: body)
        let (data, response) = try await performRequest(req)
        guard let http = response as? HTTPURLResponse else { throw AppError.networkError }

        if http.statusCode == 401 {
            try await refresh()
            let retried = buildMultipartRequest(for: endpoint, boundary: boundary, body: body)
            let (retryData, retryResponse) = try await performRequest(retried)
            guard let retryHttp = retryResponse as? HTTPURLResponse else { throw AppError.networkError }
            if retryHttp.statusCode == 401 {
                handleSessionExpiry()
                throw AppError.unauthorized
            }
            return try decode(retryData, statusCode: retryHttp.statusCode)
        }

        return try decode(data, statusCode: http.statusCode)
    }

    func requestEmpty(_ endpoint: APIEndpoint) async throws {
        let req = buildRequest(for: endpoint)
        let (_, response) = try await performRequest(req)
        guard let http = response as? HTTPURLResponse else { throw AppError.networkError }

        if http.statusCode == 401 {
            try await refresh()
            let retried = buildRequest(for: endpoint)
            let (_, retryResponse) = try await performRequest(retried)
            guard let retryHttp = retryResponse as? HTTPURLResponse else { throw AppError.networkError }
            if retryHttp.statusCode == 401 {
                handleSessionExpiry()
                throw AppError.unauthorized
            }
            guard (200...299).contains(retryHttp.statusCode) else {
                throw AppError.serverError(statusCode: retryHttp.statusCode)
            }
            return
        }

        guard (200...299).contains(http.statusCode) else {
            throw AppError.serverError(statusCode: http.statusCode)
        }
    }

    // MARK: - Private

    private func buildRequest(for endpoint: APIEndpoint) -> URLRequest {
        var request = URLRequest(url: endpoint.url(baseURL: baseURL))
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = endpoint.bodyData
        if endpoint.requiresAuth, let token = tokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func buildMultipartRequest(for endpoint: APIEndpoint, boundary: String, body: Data) -> URLRequest {
        var request = URLRequest(url: endpoint.url(baseURL: baseURL))
        request.httpMethod = endpoint.method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        if endpoint.requiresAuth, let token = tokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func makeMultipartBody(boundary: String, fields: [String: String], file: MultipartFile) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (key, value) in fields {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(file.field)\"; filename=\"\(file.filename)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(file.data)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw AppError.networkError
        }
    }

    private func decode<T: Decodable>(_ data: Data, statusCode: Int) throws -> T {
        guard (200...299).contains(statusCode) else {
            throw statusCode == 404 ? AppError.notFound : AppError.serverError(statusCode: statusCode)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        do {
            let envelope = try decoder.decode(APIResponse<T>.self, from: data)
            guard let value = envelope.data else { throw AppError.decodingError }
            return value
        } catch is DecodingError {
            throw AppError.decodingError
        }
    }

    private func refresh() async throws {
        guard let refreshToken = tokenStore.refreshToken else {
            handleSessionExpiry()
            throw AppError.unauthorized
        }
        var request = URLRequest(url: URL(string: refreshBaseURL + "/api/v1/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try? encoder.encode(RefreshRequestDTO(refreshToken: refreshToken))

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            handleSessionExpiry()
            throw AppError.unauthorized
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(APIResponse<TokenPairDTO>.self, from: data),
              let pair = envelope.data else {
            handleSessionExpiry()
            throw AppError.unauthorized
        }
        tokenStore.save(access: pair.accessToken, refresh: pair.refreshToken)
    }

    private func handleSessionExpiry() {
        tokenStore.clear()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
}
