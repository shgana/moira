import Foundation
import Observation

@Observable
final class AppState {
    private let defaults = UserDefaults.standard
    private let recentsKey = "moira.recentRestaurantIDs"
    static let maxRecentlyViewed = 5

    var selectedTab: RootTab = .search
    var recentRestaurantIDs: [String]
    var searchServiceStatus: ServiceStatus
    var proxyBaseURL: URL?

    init() {
        recentRestaurantIDs = defaults.stringArray(forKey: recentsKey) ?? []
        let initialURL = ProxyConfiguration.currentBaseURL()
        proxyBaseURL = initialURL
        searchServiceStatus = initialURL == nil ? .notConfigured : .live
    }

    func markViewed(_ restaurantID: UUID) {
        let id = restaurantID.uuidString
        recentRestaurantIDs.removeAll { $0 == id }
        recentRestaurantIDs.insert(id, at: 0)
        recentRestaurantIDs = Array(recentRestaurantIDs.prefix(Self.maxRecentlyViewed))
        defaults.set(recentRestaurantIDs, forKey: recentsKey)
    }

    func clearRecentlyViewed() {
        recentRestaurantIDs = []
        defaults.removeObject(forKey: recentsKey)
    }

    @discardableResult
    func setProxyBaseURL(_ raw: String?) -> Bool {
        let resolved = ProxyConfiguration.setBaseURL(raw)
        proxyBaseURL = resolved
        searchServiceStatus = resolved == nil ? .notConfigured : .live
        return resolved != nil
    }

    func noteProxyFailure() {
        searchServiceStatus = .proxyUnavailable
    }

    func noteProxySuccess() {
        searchServiceStatus = .live
    }

    func noteProxyMissing() {
        searchServiceStatus = .notConfigured
    }
}

enum RootTab: Hashable {
    case search
    case saved
    case profile
}
