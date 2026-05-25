import SwiftUI

struct RestaurantRowView: View {
    let restaurant: Restaurant
    var showStatusChip: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MoiraTheme.surfaceMuted, Color(red: 0.87, green: 0.88, blue: 0.87)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(MoiraTheme.ink.opacity(0.75))
                )
                .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(MoiraTheme.ink)
                        Text("\(restaurant.cuisine.uppercased()) • \(restaurant.city)")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(MoiraTheme.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    ScoreRingView(score: restaurant.moiraScoreValue, confidence: restaurant.confidence, size: 70)
                }

                HStack(spacing: 12) {
                    if let google = restaurant.googleRating {
                        Label("\(google, specifier: "%.1f") G", systemImage: "star.fill")
                    }
                    if let yelp = restaurant.yelpRating {
                        Label("\(yelp, specifier: "%.1f") Y", systemImage: "star.leadinghalf.filled")
                    }
                    if let beli = restaurant.beliScore {
                        Label("\(beli, specifier: "%.1f") B", systemImage: "fork.knife")
                    }
                }
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(MoiraTheme.secondaryText)

                if showStatusChip {
                    Text(restaurant.listStatus.rawValue)
                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                        .foregroundStyle(MoiraTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MoiraTheme.surfaceMuted, in: Capsule())
                }
            }
        }
        .moiraCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(restaurant.name), \(restaurant.cuisine), score \(restaurant.moiraScoreValue ?? 0, specifier: "%.1f"), confidence \(restaurant.confidence.rawValue)")
        .accessibilityHint("Opens restaurant details.")
    }
}
