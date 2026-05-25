import Foundation
import Observation

@Observable
final class AppState {
    private let defaults = UserDefaults.standard
    private let recentsKey = "moira.recentRestaurantIDs"

    var selectedTab: RootTab = .search
    var recentRestaurantIDs: [String]
    var searchServiceStatus: ServiceStatus

    init(searchServiceStatus: ServiceStatus = .notConfigured) {
        self.searchServiceStatus = searchServiceStatus
        recentRestaurantIDs = defaults.stringArray(forKey: recentsKey) ?? []
    }

    func markViewed(_ restaurantID: UUID) {
        let id = restaurantID.uuidString
        recentRestaurantIDs.removeAll { $0 == id }
        recentRestaurantIDs.insert(id, at: 0)
        recentRestaurantIDs = Array(recentRestaurantIDs.prefix(8))
        defaults.set(recentRestaurantIDs, forKey: recentsKey)
    }

    func clearRecentlyViewed() {
        recentRestaurantIDs = []
        defaults.removeObject(forKey: recentsKey)
    }
}

enum RootTab: Hashable {
    case search
    case saved
    case profile
}
