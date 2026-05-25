import XCTest
@testable import Moira

final class ScoreEngineTests: XCTestCase {
    func testRenormalizesWhenSourceMissing() {
        let snapshot = ScoreEngine.compute(
            google: 4.5,
            googleReviewCount: 220,
            yelp: nil,
            yelpReviewCount: 0,
            beli: 8.0
        )

        XCTAssertEqual(snapshot.score, 8.4)
        XCTAssertEqual(snapshot.confidence, .moderate)
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
}
