import SwiftUI
import SwiftData

struct AddRestaurantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query private var restaurants: [Restaurant]

    let searchService: AnyRestaurantSearchService
    var preselectedCandidate: PlaceCandidate? = nil
    var existingRestaurant: Restaurant? = nil

    @State private var query = ""
    @State private var results: [PlaceCandidate] = []
    @State private var selectedCandidate: PlaceCandidate?
    @State private var customName = ""
    @State private var customCuisine = ""
    @State private var customAddress = ""
    @State private var customCity = ""
    @State private var beliScoreText = ""
    @State private var notes = ""
    @State private var listStatus: ListStatus = .wantToTry
    @State private var isSearching = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var routedExistingRestaurant: Restaurant?

    var body: some View {
        NavigationStack {
            Form {
                if let matchedExistingRestaurant {
                    Section("Already Saved") {
                        Text("\(matchedExistingRestaurant.name) is already in your library.")
                        Text("This Google Place match already exists, so Moira should route you to the saved record instead of creating a duplicate.")
                            .foregroundStyle(.secondary)
                        Button("Open Saved Record") {
                            routedExistingRestaurant = matchedExistingRestaurant
                        }
                    }
                }

                Section("Search Google Places") {
                    TextField("Search restaurants", text: $query)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Button {
                        selectManualEntry()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Without a Google Match")
                            Text("Use local-only details now, then enter Beli or notes manually.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if isSearching {
                        ProgressView()
                    }

                    ForEach(results) { candidate in
                        Button {
                            apply(candidate: candidate)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(candidate.name)
                                Text("\(candidate.cuisine) • \(candidate.city)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Restaurant Info") {
                    TextField("Name", text: $customName)
                    TextField("Cuisine", text: $customCuisine)
                    TextField("Address", text: $customAddress)
                    TextField("City", text: $customCity)
                }

                Section("Moira Inputs") {
                    TextField("Beli score (0-10)", text: $beliScoreText)
                        .keyboardType(.decimalPad)
                    Picker("Save to", selection: $listStatus) {
                        ForEach(ListStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("Google and Yelp values are aggregate ratings only. Moira does not claim NLP, bot detection, or hidden review analysis in v1.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(existingRestaurant == nil ? "Add Restaurant" : "Edit Existing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(existingRestaurant == nil ? "Save" : "Update") {
                        Task { await save() }
                    }
                    .disabled(isSaving || customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task {
                if let preselectedCandidate {
                    apply(candidate: preselectedCandidate)
                    results = [preselectedCandidate]
                }
            }
            .task(id: query) {
                guard preselectedCandidate == nil else { return }
                await runSearch()
            }
            .navigationDestination(item: $routedExistingRestaurant) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
        }
    }

    @MainActor
    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        isSearching = true
        defer { isSearching = false }
        do {
            results = try await searchService.search(query: trimmed)
            errorMessage = nil
        } catch {
            results = []
            if let searchError = error as? SearchServiceError {
                switch searchError {
                case .notConfigured:
                    appState.searchServiceStatus = .notConfigured
                    errorMessage = "Search is unavailable until the proxy base URL is configured."
                case .invalidResponse:
                    appState.searchServiceStatus = .proxyUnavailable
                    errorMessage = "Search failed."
                case .candidateNotFound:
                    errorMessage = "That restaurant could not be loaded."
                }
            } else {
                appState.searchServiceStatus = .proxyUnavailable
                errorMessage = "Search failed."
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let beliScore = Double(beliScoreText)
        let restaurant = existingRestaurant ?? duplicateMatch() ?? Restaurant(name: customName, address: customAddress)
        let selectedPlaceID = selectedCandidate?.id

        if let selectedPlaceID {
            do {
                selectedCandidate = try await searchService.placeDetails(for: selectedPlaceID)
                appState.searchServiceStatus = .live
            } catch {
                if let searchError = error as? SearchServiceError, searchError == .notConfigured {
                    appState.searchServiceStatus = .notConfigured
                    errorMessage = "Google and Yelp refresh is unavailable until the proxy base URL is configured. You can still save manual details."
                } else {
                    appState.searchServiceStatus = .proxyUnavailable
                    errorMessage = "Could not refresh Google/Yelp details. You can still save what is already loaded."
                }
            }
        }

        restaurant.name = customName
        restaurant.cuisine = customCuisine.isEmpty ? "Uncategorized" : customCuisine
        restaurant.address = customAddress
        restaurant.city = customCity
        restaurant.placeID = selectedCandidate?.id ?? restaurant.placeID
        restaurant.neighborhood = selectedCandidate?.neighborhood ?? restaurant.neighborhood
        restaurant.latitude = selectedCandidate?.latitude ?? restaurant.latitude
        restaurant.longitude = selectedCandidate?.longitude ?? restaurant.longitude
        restaurant.photoURL = selectedCandidate?.photoURL ?? restaurant.photoURL
        restaurant.priceLevel = selectedCandidate?.priceLevel ?? restaurant.priceLevel
        restaurant.googleRating = selectedCandidate?.googleRating ?? restaurant.googleRating
        restaurant.googleReviewCount = selectedCandidate?.googleReviewCount ?? restaurant.googleReviewCount
        restaurant.yelpRating = selectedCandidate?.yelpRating ?? restaurant.yelpRating
        restaurant.yelpReviewCount = selectedCandidate?.yelpReviewCount ?? restaurant.yelpReviewCount
        restaurant.beliScore = beliScore
        restaurant.listStatus = listStatus
        restaurant.notes = notes
        restaurant.refreshComputedValues()

        if existingRestaurant == nil && duplicateMatch() == nil {
            modelContext.insert(restaurant)
        }

        try? modelContext.save()
        dismiss()
    }

    private func selectManualEntry() {
        selectedCandidate = nil
        routedExistingRestaurant = nil
        errorMessage = nil
        if customCuisine.isEmpty {
            customCuisine = "Uncategorized"
        }
    }

    private func apply(candidate: PlaceCandidate) {
        selectedCandidate = candidate
        routedExistingRestaurant = nil
        customName = candidate.name
        customCuisine = candidate.cuisine
        customAddress = candidate.address
        customCity = candidate.city
    }

    private var matchedExistingRestaurant: Restaurant? {
        existingRestaurant ?? duplicateMatch()
    }

    private func duplicateMatch() -> Restaurant? {
        if let placeID = selectedCandidate?.id,
           let exact = restaurants.first(where: { $0.placeID == placeID }) {
            return exact
        }

        guard let selectedCandidate else { return nil }
        return restaurants.first(where: { $0.normalizedIdentity == selectedCandidate.normalizedIdentity })
    }
}
