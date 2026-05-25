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

struct SearchServicePackage {
    let service: AnyRestaurantSearchService
    let status: ServiceStatus
}

enum SearchServiceFactory {
    static func make() -> SearchServicePackage {
        if let configuration = ProxyConfiguration.fromBundle() {
            return SearchServicePackage(
                service: AnyRestaurantSearchService(RemoteRestaurantSearchService(configuration: configuration)),
                status: .live
            )
        }

        return SearchServicePackage(
            service: AnyRestaurantSearchService(UnavailableRestaurantSearchService()),
            status: .notConfigured
        )
    }
}

struct ProxyConfiguration: Sendable {
    let baseURL: URL

    static func fromBundle(_ bundle: Bundle = .main) -> ProxyConfiguration? {
        guard
            let rawValue = bundle.object(forInfoDictionaryKey: "MOIRA_PROXY_BASE_URL") as? String,
            let url = URL(string: rawValue.trimmingCharacters(in: .whitespacesAndNewlines)),
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return ProxyConfiguration(baseURL: url)
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
    let latitude: Double?
    let longitude: Double?
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
            latitude: latitude,
            longitude: longitude,
            photoURL: photoURL,
            googleRating: googleRating,
            googleReviewCount: googleReviewCount,
            yelpRating: yelpRating,
            yelpReviewCount: yelpReviewCount
        )
    }
}

struct RemoteRestaurantSearchService: RestaurantSearchProviding {
    let configuration: ProxyConfiguration
    private let session: URLSession = .shared

    func search(query: String) async throws -> [PlaceCandidate] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        var components = URLComponents(url: configuration.baseURL.appending(path: "api/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
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
        let url = configuration.baseURL.appending(path: "api/place").appending(path: placeID)
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

struct UnavailableRestaurantSearchService: RestaurantSearchProviding {
    func search(query: String) async throws -> [PlaceCandidate] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        throw SearchServiceError.notConfigured
    }

    func placeDetails(for placeID: String) async throws -> PlaceCandidate {
        throw SearchServiceError.notConfigured
    }
}
