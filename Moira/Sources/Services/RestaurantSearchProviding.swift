import Foundation

protocol RestaurantSearchProviding {
    func search(query: String) async throws -> [PlaceCandidate]
    func placeDetails(for placeID: String) async throws -> PlaceCandidate
}

enum ServiceStatus: String {
    case live = "Proxy configured"
    case notConfigured = "Proxy not configured"
    case proxyUnavailable = "Proxy unavailable"
}

struct AnyRestaurantSearchService: RestaurantSearchProviding {
    private let searchHandler: (String) async throws -> [PlaceCandidate]
    private let placeHandler: (String) async throws -> PlaceCandidate

    init<Service: RestaurantSearchProviding>(_ service: Service) {
        self.searchHandler = service.search
        self.placeHandler = service.placeDetails
    }

    func search(query: String) async throws -> [PlaceCandidate] {
        try await searchHandler(query)
    }

    func placeDetails(for placeID: String) async throws -> PlaceCandidate {
        try await placeHandler(placeID)
    }
}

enum ProxyConfiguration {
    static let userDefaultsKey = "moira.proxyBaseURL"

    static func currentBaseURL(defaults: UserDefaults = .standard, bundle: Bundle = .main) -> URL? {
        if let override = defaults.string(forKey: userDefaultsKey),
           let url = sanitizedURL(override) {
            return url
        }
        if let raw = bundle.object(forInfoDictionaryKey: "MOIRA_PROXY_BASE_URL") as? String,
           let url = sanitizedURL(raw) {
            return url
        }
        return nil
    }

    static func setBaseURL(_ raw: String?, defaults: UserDefaults = .standard) -> URL? {
        guard let raw, let url = sanitizedURL(raw) else {
            defaults.removeObject(forKey: userDefaultsKey)
            return nil
        }
        defaults.set(url.absoluteString, forKey: userDefaultsKey)
        return url
    }

    private static func sanitizedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return url
    }
}

enum SearchServiceFactory {
    static func make() -> AnyRestaurantSearchService {
        AnyRestaurantSearchService(RemoteRestaurantSearchService())
    }
}

enum SearchServiceError: LocalizedError, Equatable {
    case invalidResponse
    case candidateNotFound
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The proxy returned an invalid response."
        case .candidateNotFound:
            return "The selected restaurant could not be found."
        case .notConfigured:
            return "Restaurant search is unavailable until the Moira proxy base URL is configured."
        }
    }
}

private struct ProxySearchResponse: Decodable {
    let results: [ProxyPlace]
}

private struct ProxyPlace: Decodable {
    let id: String
    let name: String
    let cuisine: String
    let address: String
    let city: String
    let neighborhood: String?
    let latitude: Double?
    let longitude: Double?
    let priceLevel: Int?
    let photoURL: String?
    let googleRating: Double?
    let googleReviewCount: Int
    let yelpRating: Double?
    let yelpReviewCount: Int

    func toCandidate() -> PlaceCandidate {
        PlaceCandidate(
            id: id,
            name: name,
            cuisine: cuisine,
            address: address,
            city: city,
            neighborhood: neighborhood,
            latitude: latitude,
            longitude: longitude,
            priceLevel: priceLevel,
            photoURL: photoURL,
            googleRating: googleRating,
            googleReviewCount: googleReviewCount,
            yelpRating: yelpRating,
            yelpReviewCount: yelpReviewCount
        )
    }
}

struct RemoteRestaurantSearchService: RestaurantSearchProviding {
    private let session: URLSession = .shared
    private let urlProvider: () -> URL?

    init(urlProvider: @escaping () -> URL? = { ProxyConfiguration.currentBaseURL() }) {
        self.urlProvider = urlProvider
    }

    func search(query: String) async throws -> [PlaceCandidate] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }
        guard let baseURL = urlProvider() else { throw SearchServiceError.notConfigured }

        var components = URLComponents(url: baseURL.appending(path: "api/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmedQuery)]
        guard let url = components?.url else { throw SearchServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SearchServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
        return decoded.results.map { $0.toCandidate() }
    }

    func placeDetails(for placeID: String) async throws -> PlaceCandidate {
        guard let baseURL = urlProvider() else { throw SearchServiceError.notConfigured }
        let url = baseURL.appending(path: "api/place").appending(path: placeID)
        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SearchServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ProxyPlace.self, from: data)
        return decoded.toCandidate()
    }
}
