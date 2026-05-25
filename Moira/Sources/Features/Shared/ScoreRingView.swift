import SwiftUI

struct ScoreRingView: View {
    let score: Double?
    let confidence: ConfidenceLevel
    var size: CGFloat = 116

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoiraTheme.line, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    MoiraTheme.confidenceColor(confidence),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(score.map { String(format: "%.1f", $0) } ?? "—")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(MoiraTheme.ink)
                Text(confidence.rawValue)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(MoiraTheme.confidenceColor(confidence))
            }
        }
        .frame(width: size, height: size)
    }

    private var progress: CGFloat {
        CGFloat((score ?? 0) / 10.0)
    }
}
