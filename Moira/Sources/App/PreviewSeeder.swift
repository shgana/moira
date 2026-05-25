import Foundation
import SwiftData

enum PreviewSeeder {
    static var shouldSeedDemoData: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || environment["MOIRA_ENABLE_DEMO_DATA"] == "1"
    }

    static func seedIfNeeded(in context: ModelContext) throws {
        var descriptor = FetchDescriptor<Restaurant>()
        descriptor.fetchLimit = 1
        if try !context.fetch(descriptor).isEmpty {
            return
        }

        let restaurants = [
            Restaurant(
                name: "Cote Korean Steakhouse",
                cuisine: "Korean Steakhouse",
                address: "16 W 22nd St",
                city: "New York, NY",
                latitude: 40.7416,
                longitude: -73.9910,
                placeID: "seed_cote",
                googleRating: 4.8,
                googleReviewCount: 7120,
                yelpRating: 4.5,
                yelpReviewCount: 2804,
                beliScore: 9.3,
                listStatus: .favorites,
                notes: "Reliable for steak-heavy group dinners."
            ),
            Restaurant(
                name: "Lilia",
                cuisine: "Italian",
                address: "567 Union Ave",
                city: "Brooklyn, NY",
                latitude: 40.7142,
                longitude: -73.9506,
                placeID: "seed_lilia",
                googleRating: 4.7,
                googleReviewCount: 6341,
                yelpRating: 4.3,
                yelpReviewCount: 1844,
                beliScore: 8.9,
                listStatus: .wantToTry,
                notes: "Need to compare pasta hype versus actual consistency."
            ),
            Restaurant(
                name: "Dame",
                cuisine: "Seafood",
                address: "87 MacDougal St",
                city: "New York, NY",
                latitude: 40.7287,
                longitude: -74.0017,
                placeID: "seed_dame",
                googleRating: 4.5,
                googleReviewCount: 497,
                yelpRating: 4.4,
                yelpReviewCount: 201,
                beliScore: nil,
                listStatus: .tried,
                notes: "Strong fish sandwich, still need Beli entry."
            )
        ]

        restaurants.forEach(context.insert)
        try context.save()
    }
}
