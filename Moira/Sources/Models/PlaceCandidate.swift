import Foundation

struct PlaceCandidate: Identifiable, Hashable {
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

    var normalizedIdentity: String {
        let combined = "\(name)|\(address)"
        return combined
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9|]", with: "", options: .regularExpression)
    }

    var locationCaption: String {
        if let neighborhood, !neighborhood.isEmpty { return neighborhood }
        return city
    }

    var priceLevelDisplay: String? {
        guard let priceLevel else { return nil }
        let clamped = max(0, min(priceLevel, 4))
        if clamped == 0 { return "Free" }
        return String(repeating: "$", count: clamped)
    }

    func toRestaurant(beliScore: Double?, listStatus: ListStatus, notes: String) -> Restaurant {
        Restaurant(
            name: name,
            cuisine: cuisine,
            address: address,
            city: city,
            neighborhood: neighborhood,
            latitude: latitude,
            longitude: longitude,
            placeID: id,
            photoURL: photoURL,
            priceLevel: priceLevel,
            googleRating: googleRating,
            googleReviewCount: googleReviewCount,
            yelpRating: yelpRating,
            yelpReviewCount: yelpReviewCount,
            beliScore: beliScore,
            listStatus: listStatus,
            notes: notes
        )
    }
}
