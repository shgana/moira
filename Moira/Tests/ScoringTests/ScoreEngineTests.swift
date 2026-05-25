import XCTest
@testable import Moira

final class ScoreEngineTests: XCTestCase {
    // PRD §4.3 worked example — Google 4.2, Yelp 3.8, Beli 8.9 → 8.5
    func testWorkedExampleAllSourcesPresent() {
        let snapshot = ScoreEngine.compute(
            google: 4.2,
            googleReviewCount: 400,
            yelp: 3.8,
            yelpReviewCount: 120,
            beli: 8.9
        )

        XCTAssertEqual(snapshot.score, 8.5)
        XCTAssertEqual(snapshot.normalizedSources["google"] ?? -1, 8.4, accuracy: 0.0001)
        XCTAssertEqual(snapshot.normalizedSources["yelp"] ?? -1, 7.6, accuracy: 0.0001)
        XCTAssertEqual(snapshot.normalizedSources["beli"] ?? -1, 8.9, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["beli"] ?? -1, 0.50, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["google"] ?? -1, 0.30, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["yelp"] ?? -1, 0.20, accuracy: 0.0001)
    }

    // PRD §4.3 worked example — Google 4.6, Yelp absent, Beli 8.4 → 8.7
    func testWorkedExampleMissingYelpRenormalizes() {
        let snapshot = ScoreEngine.compute(
            google: 4.6,
            googleReviewCount: 200,
            yelp: nil,
            yelpReviewCount: 0,
            beli: 8.4
        )

        XCTAssertEqual(snapshot.score, 8.7)
        XCTAssertEqual(snapshot.effectiveWeights["google"] ?? -1, 0.375, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["beli"] ?? -1, 0.625, accuracy: 0.0001)
        XCTAssertNil(snapshot.normalizedSources["yelp"])
    }

    func testRenormalizesWhenSourceMissing() {
        let snapshot = ScoreEngine.compute(
            google: 4.5,
            googleReviewCount: 220,
            yelp: nil,
            yelpReviewCount: 0,
            beli: 8.0
        )

        XCTAssertEqual(snapshot.score, 8.4)
        // 2 sources, 220 reviews, spread 1.0 → HIGH per PRD §4.4.
        XCTAssertEqual(snapshot.confidence, .high)
        XCTAssertEqual(snapshot.normalizedSources["google"] ?? -1, 9.0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.normalizedSources["beli"] ?? -1, 8.0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["google"] ?? -1, 0.375, accuracy: 0.0001)
        XCTAssertEqual(snapshot.effectiveWeights["beli"] ?? -1, 0.625, accuracy: 0.0001)
        XCTAssertEqual(snapshot.weightedContributions["google"] ?? -1, 3.375, accuracy: 0.0001)
        XCTAssertEqual(snapshot.weightedContributions["beli"] ?? -1, 5.0, accuracy: 0.0001)
    }

    func testHighConfidenceNeedsAgreementAndVolume() {
        let snapshot = ScoreEngine.compute(
            google: 4.7,
            googleReviewCount: 680,
            yelp: 4.5,
            yelpReviewCount: 240,
            beli: 9.0
        )

        XCTAssertEqual(snapshot.score, 9.1)
        XCTAssertEqual(snapshot.confidence, .high)
    }

    func testModerateWhenReviewsAreThinButSourcesAgree() {
        // 2 sources, only 40 total reviews, spread 0.4 → MODERATE via tight spread.
        let snapshot = ScoreEngine.compute(
            google: 4.4,
            googleReviewCount: 25,
            yelp: 4.2,
            yelpReviewCount: 15,
            beli: nil
        )

        XCTAssertEqual(snapshot.confidence, .moderate)
    }

    func testModerateWhenReviewsAreManyButSpreadIsWide() {
        // 2 sources, 600 total reviews, spread 4.0 → MODERATE via volume.
        let snapshot = ScoreEngine.compute(
            google: 4.8,
            googleReviewCount: 400,
            yelp: 2.8,
            yelpReviewCount: 200,
            beli: nil
        )

        XCTAssertEqual(snapshot.confidence, .moderate)
    }

    func testLowConfidenceForSparseData() {
        let snapshot = ScoreEngine.compute(
            google: 3.9,
            googleReviewCount: 18,
            yelp: nil,
            yelpReviewCount: 0,
            beli: nil
        )

        XCTAssertEqual(snapshot.score, 7.8)
        XCTAssertEqual(snapshot.confidence, .low)
    }

    func testNoSourcesYieldsNilScoreAndLow() {
        let snapshot = ScoreEngine.compute(
            google: nil,
            googleReviewCount: 0,
            yelp: nil,
            yelpReviewCount: 0,
            beli: nil
        )

        XCTAssertNil(snapshot.score)
        XCTAssertEqual(snapshot.confidence, .low)
        XCTAssertTrue(snapshot.normalizedSources.isEmpty)
    }
}
