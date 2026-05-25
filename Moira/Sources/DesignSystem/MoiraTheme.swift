import SwiftUI

enum MoiraTheme {
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.11)
    static let secondaryText = Color(red: 0.27, green: 0.28, blue: 0.28)
    static let line = Color(red: 0.90, green: 0.90, blue: 0.90)
    static let good = Color(red: 0.29, green: 0.69, blue: 0.31)
    static let caution = Color(red: 1.0, green: 0.70, blue: 0.0)
    static let weak = Color(red: 0.90, green: 0.45, blue: 0.45)

    static func scoreColor(for score: Double?) -> Color {
        guard let score else { return line }
        switch score {
        case 8.5...: return good
        case 7.0..<8.5: return caution
        default: return weak
        }
    }

    static func confidenceColor(_ confidence: ConfidenceLevel) -> Color {
        switch confidence {
        case .high: good
        case .moderate: caution
        case .low: weak
        }
    }
}

extension View {
    func moiraCard() -> some View {
        self
            .padding(20)
            .background(MoiraTheme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(MoiraTheme.line, lineWidth: 1)
            )
    }
}
