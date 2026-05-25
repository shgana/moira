import Foundation
import SwiftData

enum ListStatus: String, CaseIterable, Codable, Identifiable {
    case wantToTry = "Want to Try"
    case favorites = "Favorites"
    case tried = "Tried"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .wantToTry: "bookmark"
        case .favorites: "heart"
        case .tried: "checkmark.circle"
        }
    }
}

enum ConfidenceLevel: String, CaseIterable, Codable, Identifiable {
    case high = "HIGH"
    case moderate = "MODERATE"
    case low = "LOW"

    var id: String { rawValue }
}

@Model
final class Restaurant {
    @Attribute(.unique) var id: UUID
    var name: String
    var cuisine: String
    var address: String
    var city: String
    var neighborhood: String?
    var latitude: Double?
    var longitude: Double?
    var placeID: String?
    var photoURL: String?
    var priceLevel: Int?

    var googleRating: Double?
    var googleReviewCount: Int
    var yelpRating: Double?
    var yelpReviewCount: Int
    var beliScore: Double?

    var moiraScoreValue: Double?
    var confidenceRawValue: String

    var listStatusRawValue: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var lastViewedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        cuisine: String = "Uncategorized",
        address: String,
        city: String = "",
        neighborhood: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeID: String? = nil,
        photoURL: String? = nil,
        priceLevel: Int? = nil,
        googleRating: Double? = nil,
        googleReviewCount: Int = 0,
        yelpRating: Double? = nil,
        yelpReviewCount: Int = 0,
        beliScore: Double? = nil,
        listStatus: ListStatus = .wantToTry,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastViewedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.address = address
        self.city = city
        self.neighborhood = neighborhood
        self.latitude = latitude
        self.longitude = longitude
        self.placeID = placeID
        self.photoURL = photoURL
        self.priceLevel = priceLevel
        self.googleRating = googleRating
        self.googleReviewCount = googleReviewCount
        self.yelpRating = yelpRating
        self.yelpReviewCount = yelpReviewCount
        self.beliScore = beliScore
        self.listStatusRawValue = listStatus.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastViewedAt = lastViewedAt
        self.moiraScoreValue = nil
        self.confidenceRawValue = ConfidenceLevel.low.rawValue
        refreshComputedValues()
    }
}

extension Restaurant {
    var normalizedIdentity: String {
        let combined = "\(name)|\(address)"
        return combined
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9|]", with: "", options: .regularExpression)
    }

    var listStatus: ListStatus {
        get { ListStatus(rawValue: listStatusRawValue) ?? .wantToTry }
        set { listStatusRawValue = newValue.rawValue }
    }

    var confidence: ConfidenceLevel {
        get { ConfidenceLevel(rawValue: confidenceRawValue) ?? .low }
        set { confidenceRawValue = newValue.rawValue }
    }

    var cityLine: String {
        let region = neighborhood?.isEmpty == false ? neighborhood! : city
        if region.isEmpty { return address }
        return "\(address) • \(region)"
    }

    var locationCaption: String {
        if let neighborhood, !neighborhood.isEmpty { return neighborhood }
        if !city.isEmpty { return city }
        return address
    }

    var priceLevelDisplay: String? {
        guard let priceLevel else { return nil }
        let clamped = max(0, min(priceLevel, 4))
        if clamped == 0 { return "Free" }
        return String(repeating: "$", count: clamped)
    }

    var hasAnySource: Bool {
        googleRating != nil || yelpRating != nil || beliScore != nil
    }

    func refreshComputedValues() {
        let snapshot = ScoreEngine.compute(
            google: googleRating,
            googleReviewCount: googleReviewCount,
            yelp: yelpRating,
            yelpReviewCount: yelpReviewCount,
            beli: beliScore
        )
        moiraScoreValue = snapshot.score
        confidence = snapshot.confidence
        updatedAt = .now
    }

    func markViewed() {
        lastViewedAt = .now
        updatedAt = .now
    }
}
