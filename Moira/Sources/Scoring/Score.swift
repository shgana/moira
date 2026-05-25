import Foundation

struct ScoreSnapshot: Equatable {
    let score: Double?
    let confidence: ConfidenceLevel
    let normalizedSources: [String: Double]
    let effectiveWeights: [String: Double]
    let weightedContributions: [String: Double]
}

enum ScoreEngine {
    private static let weights: [String: Double] = [
        "google": 0.30,
        "yelp": 0.20,
        "beli": 0.50
    ]

    static func compute(
        google: Double?,
        googleReviewCount: Int,
        yelp: Double?,
        yelpReviewCount: Int,
        beli: Double?
    ) -> ScoreSnapshot {
        var normalized: [String: Double] = [:]
        if let google { normalized["google"] = google * 2.0 }
        if let yelp { normalized["yelp"] = yelp * 2.0 }
        if let beli { normalized["beli"] = beli }

        guard !normalized.isEmpty else {
            return ScoreSnapshot(
                score: nil,
                confidence: .low,
                normalizedSources: [:],
                effectiveWeights: [:],
                weightedContributions: [:]
            )
        }

        let availableWeight = normalized.keys.reduce(0.0) { $0 + (weights[$1] ?? 0) }
        let effectiveWeights = normalized.reduce(into: [String: Double]()) { partial, entry in
            partial[entry.key] = (weights[entry.key] ?? 0) / availableWeight
        }
        let weightedContributions = normalized.reduce(into: [String: Double]()) { partial, entry in
            partial[entry.key] = entry.value * (effectiveWeights[entry.key] ?? 0)
        }
        let weightedTotal = weightedContributions.values.reduce(0.0, +)
        let rounded = (weightedTotal * 10).rounded() / 10

        let reviewVolume = googleReviewCount + yelpReviewCount
        let spread = (normalized.values.max() ?? 0) - (normalized.values.min() ?? 0)
        let confidence = computeConfidence(
            sourceCount: normalized.count,
            reviewVolume: reviewVolume,
            spread: spread
        )

        return ScoreSnapshot(
            score: rounded,
            confidence: confidence,
            normalizedSources: normalized,
            effectiveWeights: effectiveWeights,
            weightedContributions: weightedContributions
        )
    }

    private static func computeConfidence(sourceCount: Int, reviewVolume: Int, spread: Double) -> ConfidenceLevel {
        if sourceCount >= 2 && reviewVolume >= 150 && spread <= 1.5 {
            return .high
        }
        if sourceCount >= 2 && (reviewVolume >= 50 || spread <= 2.5) {
            return .moderate
        }
        return .low
    }
}
