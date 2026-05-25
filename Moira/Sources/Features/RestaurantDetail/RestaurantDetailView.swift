import MapKit
import SwiftUI
import SwiftData

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(AppState.self) private var appState

    @Bindable var restaurant: Restaurant
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    private var scoreSnapshot: ScoreSnapshot {
        ScoreEngine.compute(
            google: restaurant.googleRating,
            googleReviewCount: restaurant.googleReviewCount,
            yelp: restaurant.yelpRating,
            yelpReviewCount: restaurant.yelpReviewCount,
            beli: restaurant.beliScore
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                scoreSection
                breakdownSection
                calculationSection
                notesSection
                actionsSection
            }
            .padding(20)
        }
        .background(MoiraTheme.background.ignoresSafeArea())
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditRestaurantSheet(restaurant: restaurant)
        }
        .confirmationDialog("Delete restaurant?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(restaurant)
                try? modelContext.save()
            }
        }
        .onAppear {
            restaurant.markViewed()
            appState.markViewed(restaurant.id)
            try? modelContext.save()
        }
    }

    private var hero: some View {
        heroBackground
            .frame(height: 220)
            .overlay(heroOverlay, alignment: .bottomLeading)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let photoURL = restaurant.photoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    heroFallback
                }
            }
        } else {
            heroFallback
        }
    }

    private var heroFallback: some View {
        LinearGradient(
            colors: [Color(red: 0.17, green: 0.17, blue: 0.17), Color(red: 0.35, green: 0.34, blue: 0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.72)],
            startPoint: .center,
            endPoint: .bottom
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.cuisine.uppercased())
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Text(restaurant.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(restaurant.cityLine)
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(20)
        }
    }

    private var scoreSection: some View {
        HStack(spacing: 18) {
            ScoreRingView(score: restaurant.moiraScoreValue, confidence: restaurant.confidence, size: 126)
            VStack(alignment: .leading, spacing: 10) {
                Text("Moira Score")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(confidenceSummary)
                    .font(.callout)
                    .foregroundStyle(MoiraTheme.secondaryText)
                Text(reviewSummary)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(MoiraTheme.secondaryText)
            }
            Spacer()
        }
        .moiraCard()
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ratings Breakdown")
                .font(.system(.title3, design: .rounded, weight: .semibold))
            sourceRow(
                "Google",
                rating: restaurant.googleRating.map { $0 * 2 },
                display: restaurant.googleRating.map { String(format: "%.1f / 5", $0) } ?? "Missing",
                count: restaurant.googleReviewCount,
                normalized: scoreSnapshot.normalizedSources["google"],
                effectiveWeight: scoreSnapshot.effectiveWeights["google"],
                contribution: scoreSnapshot.weightedContributions["google"]
            )
            sourceRow(
                "Yelp",
                rating: restaurant.yelpRating.map { $0 * 2 },
                display: restaurant.yelpRating.map { String(format: "%.1f / 5", $0) } ?? "Missing",
                count: restaurant.yelpReviewCount,
                normalized: scoreSnapshot.normalizedSources["yelp"],
                effectiveWeight: scoreSnapshot.effectiveWeights["yelp"],
                contribution: scoreSnapshot.weightedContributions["yelp"]
            )
            sourceRow(
                "Beli",
                rating: restaurant.beliScore,
                display: restaurant.beliScore.map { String(format: "%.1f / 10", $0) } ?? "Missing",
                count: nil,
                normalized: scoreSnapshot.normalizedSources["beli"],
                effectiveWeight: scoreSnapshot.effectiveWeights["beli"],
                contribution: scoreSnapshot.weightedContributions["beli"]
            )
        }
        .moiraCard()
    }

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How we calculate this")
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text("Moira uses aggregate ratings only. Google and Yelp are normalized to a 0–10 scale, Beli is entered directly, and available weights renormalize when a source is missing.")
            Text("Trust weights: Beli 0.50, Google 0.30, Yelp 0.20.")
            if let score = scoreSnapshot.score {
                Text("Current weighted result: \(String(format: "%.1f", score)) / 10.")
            }
            Text("Confidence is based on available source count, review volume, and score agreement.")
                .foregroundStyle(MoiraTheme.secondaryText)
        }
        .font(.callout)
        .moiraCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text(restaurant.notes.isEmpty ? "No notes yet." : restaurant.notes)
                .foregroundStyle(restaurant.notes.isEmpty ? MoiraTheme.secondaryText : MoiraTheme.ink)
        }
        .moiraCard()
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button("Open in Apple Maps") {
                openMaps(usingGoogle: false)
            }
            .buttonStyle(.borderedProminent)
            .tint(MoiraTheme.ink)

            Button("Open in Google Maps") {
                openMaps(usingGoogle: true)
            }
            .buttonStyle(.bordered)
            .tint(MoiraTheme.ink)

            Button("Delete Restaurant", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
    }

    private func sourceRow(
        _ title: String,
        rating: Double?,
        display: String,
        count: Int?,
        normalized: Double?,
        effectiveWeight: Double?,
        contribution: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(display)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                if let count {
                    Text("• \(count)")
                        .foregroundStyle(MoiraTheme.secondaryText)
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(MoiraTheme.surfaceMuted)
                    Capsule()
                        .fill(MoiraTheme.ink)
                        .frame(width: geometry.size.width * CGFloat((rating ?? 0) / 10))
                }
            }
            .frame(height: 10)

            if let normalized, let effectiveWeight, let contribution {
                Text(
                    "Normalized \(String(format: "%.1f", normalized)) • effective weight \(String(format: "%.0f%%", effectiveWeight * 100)) • contribution \(String(format: "%.1f", contribution))"
                )
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(MoiraTheme.secondaryText)
            } else {
                Text("Missing from the current weighted score.")
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(MoiraTheme.secondaryText)
            }
        }
    }

    private var confidenceSummary: String {
        switch restaurant.confidence {
        case .high:
            "High confidence means strong source coverage, substantial review volume, and tight score agreement."
        case .moderate:
            "Moderate confidence means the score is usable, but at least one data signal is thin or less aligned."
        case .low:
            "Low confidence means the current score is based on sparse or inconsistent data."
        }
    }

    private var reviewSummary: String {
        let google = restaurant.googleReviewCount
        let yelp = restaurant.yelpReviewCount
        return "Google reviews: \(google) • Yelp reviews: \(yelp)"
    }

    private func openMaps(usingGoogle: Bool) {
        let encodedName = restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurant.name
        let encodedAddress = restaurant.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurant.address

        let url: URL?
        if usingGoogle {
            url = URL(string: "comgooglemaps://?q=\(encodedName),\(encodedAddress)")
                ?? URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName),\(encodedAddress)")
        } else if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            url = URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(encodedName)")
        } else {
            url = URL(string: "http://maps.apple.com/?q=\(encodedName),\(encodedAddress)")
        }

        if let url {
            openURL(url)
        }
    }
}

private struct EditRestaurantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var restaurant: Restaurant

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant") {
                    TextField("Name", text: $restaurant.name)
                    TextField("Cuisine", text: $restaurant.cuisine)
                    TextField("Address", text: $restaurant.address)
                    TextField("City", text: $restaurant.city)
                }

                Section("Ratings") {
                    OptionalNumberField(title: "Google rating", value: $restaurant.googleRating)
                    Stepper("Google reviews: \(restaurant.googleReviewCount)", value: $restaurant.googleReviewCount, in: 0...50000)
                    OptionalNumberField(title: "Yelp rating", value: $restaurant.yelpRating)
                    Stepper("Yelp reviews: \(restaurant.yelpReviewCount)", value: $restaurant.yelpReviewCount, in: 0...50000)
                    OptionalNumberField(title: "Beli score", value: $restaurant.beliScore)
                }

                Section("Save state") {
                    Picker("List", selection: $restaurant.listStatusRawValue) {
                        ForEach(ListStatus.allCases) { status in
                            Text(status.rawValue).tag(status.rawValue)
                        }
                    }
                    TextField("Notes", text: $restaurant.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        restaurant.refreshComputedValues()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct OptionalNumberField: View {
    let title: String
    @Binding var value: Double?
    @State private var text = ""

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .onAppear { text = value.map { String($0) } ?? "" }
            .onChange(of: text) { _, newValue in
                value = Double(newValue)
            }
    }
}
