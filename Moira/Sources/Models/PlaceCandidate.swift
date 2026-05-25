import Foundation

struct PlaceCandidate: Identifiable, Hashable {
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

    var normalizedIdentity: String {
        let combined = "\(name)|\(address)"
        return combined
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9|]", with: "", options: .regularExpression)
    }

    func toRestaurant(beliScore: Double?, listStatus: ListStatus, notes: String) -> Restaurant {
        Restaurant(
            name: name,
            cuisine: cuisine,
            address: address,
            city: city,
            latitude: latitude,
            longitude: longitude,
            placeID: id,
            photoURL: photoURL,
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
