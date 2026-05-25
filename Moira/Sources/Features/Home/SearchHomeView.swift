import SwiftUI
import SwiftData

struct SearchHomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Restaurant.updatedAt, order: .reverse) private var restaurants: [Restaurant]

    let searchService: AnyRestaurantSearchService

    @State private var query = ""
    @State private var results: [PlaceCandidate] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        searchField
                        if !query.isEmpty || isSearching || !results.isEmpty {
                            searchResultsSection
                        } else {
                            recentlyViewedSection
                            savedHighlightsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .padding(.bottom, 140)
                }
                .background(MoiraTheme.background.ignoresSafeArea())

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(MoiraTheme.ink, in: Circle())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 84)
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
                .accessibilityLabel("Add restaurant")
                .accessibilityHint("Opens the add restaurant flow.")
            }
            .navigationTitle("Moira")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddSheet) {
                AddRestaurantSheet(searchService: searchService)
            }
            .task(id: query) {
                await runSearch()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Is this restaurant worth eating at?")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(MoiraTheme.ink)
            Text("Search first, save selectively, and keep the score honest.")
                .font(.system(.body, design: .default))
                .foregroundStyle(MoiraTheme.secondaryText)
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MoiraTheme.secondaryText)
                TextField("Search restaurants, cuisines, neighborhoods", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(MoiraTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(MoiraTheme.line, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(MoiraTheme.weak)
            }
        }
    }

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Recently Viewed")
            if recentRestaurants.isEmpty {
                emptyCard("Your last opened restaurants will appear here.")
            } else {
                ForEach(recentRestaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRowView(restaurant: restaurant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var savedHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Saved Right Now")
            if restaurants.isEmpty {
                emptyCard("Add a restaurant from search to start building your private list.")
            } else {
                ForEach(Array(restaurants.prefix(4))) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRowView(restaurant: restaurant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle("Search Results")
                Spacer()
                if isSearching {
                    ProgressView()
                        .tint(MoiraTheme.ink)
                }
            }

            if results.isEmpty && !isSearching {
                if errorMessage != nil {
                    emptyCard("Use Add Restaurant to create a local-only entry while search is unavailable.")
                } else {
                    emptyCard("No matches found. Use Add Restaurant to create a manual entry.")
                }
            } else {
                ForEach(results) { candidate in
                    PlaceCandidateCard(candidate: candidate, existing: existingRestaurant(for: candidate), searchService: searchService)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(MoiraTheme.ink)
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(MoiraTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moiraCard()
    }

    private var recentRestaurants: [Restaurant] {
        let ids = Set(appState.recentRestaurantIDs)
        return restaurants.filter { ids.contains($0.id.uuidString) }
            .sorted {
                guard
                    let leftIndex = appState.recentRestaurantIDs.firstIndex(of: $0.id.uuidString),
                    let rightIndex = appState.recentRestaurantIDs.firstIndex(of: $1.id.uuidString)
                else { return false }
                return leftIndex < rightIndex
            }
    }

    private func existingRestaurant(for candidate: PlaceCandidate) -> Restaurant? {
        restaurants.first(where: {
            ($0.placeID != nil && $0.placeID == candidate.id) || $0.normalizedIdentity == candidate.normalizedIdentity
        })
    }

    @MainActor
    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        // Debounce — wait for the user to stop typing for 300ms before hitting the proxy.
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            results = try await searchService.search(query: trimmed)
            errorMessage = nil
            appState.noteProxySuccess()
        } catch {
            if let searchError = error as? SearchServiceError {
                switch searchError {
                case .notConfigured:
                    appState.noteProxyMissing()
                case .invalidResponse:
                    appState.noteProxyFailure()
                case .candidateNotFound:
                    break
                }
            } else {
                appState.noteProxyFailure()
            }
            results = []
            errorMessage = searchErrorMessage(for: error)
        }
    }

    private func searchErrorMessage(for error: Error) -> String {
        if let searchError = error as? SearchServiceError {
            switch searchError {
            case .notConfigured:
                return "Search is unavailable until the proxy base URL is configured. You can still add a restaurant manually."
            case .invalidResponse:
                return "Search failed. Saved restaurants still work offline."
            case .candidateNotFound:
                return "That restaurant could not be loaded. Try another result or add it manually."
            }
        }

        return "Search failed. Saved restaurants still work offline."
    }
}

private struct PlaceCandidateCard: View {
    let candidate: PlaceCandidate
    let existing: Restaurant?
    let searchService: AnyRestaurantSearchService
    @State private var showingSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(candidate.name)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(MoiraTheme.ink)

                        if let existing {
                            Text(existing.listStatus.rawValue)
                                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                                .foregroundStyle(MoiraTheme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MoiraTheme.surfaceMuted, in: Capsule())
                        }
                    }
                    Text("\(candidate.cuisine.uppercased()) • \(candidate.city)")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(MoiraTheme.secondaryText)
                    Text(candidate.address)
                        .font(.callout)
                        .foregroundStyle(MoiraTheme.secondaryText)
                }
                Spacer()

                let preview = existing.map {
                    ScoreSnapshot(
                        score: $0.moiraScoreValue,
                        confidence: $0.confidence,
                        normalizedSources: [:],
                        effectiveWeights: [:],
                        weightedContributions: [:]
                    )
                } ?? ScoreEngine.compute(
                    google: candidate.googleRating,
                    googleReviewCount: candidate.googleReviewCount,
                    yelp: candidate.yelpRating,
                    yelpReviewCount: candidate.yelpReviewCount,
                    beli: nil
                )
                ScoreRingView(score: preview.score, confidence: preview.confidence, size: 74)
            }

            HStack(spacing: 12) {
                if let google = candidate.googleRating {
                    Text("Google \(google, specifier: "%.1f") • \(candidate.googleReviewCount)")
                }
                if let yelp = candidate.yelpRating {
                    Text("Yelp \(yelp, specifier: "%.1f") • \(candidate.yelpReviewCount)")
                }
            }
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(MoiraTheme.secondaryText)

            if existing == nil {
                Button("Add to Moira") {
                    showingSheet = true
                }
                .buttonStyle(.borderedProminent)
                .tint(MoiraTheme.ink)
            } else if let existing {
                NavigationLink {
                    RestaurantDetailView(restaurant: existing)
                } label: {
                    Text("Open Saved Record")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MoiraTheme.ink)
            }
        }
        .moiraCard()
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showingSheet) {
            AddRestaurantSheet(searchService: searchService, preselectedCandidate: candidate, existingRestaurant: existing)
        }
    }
}
