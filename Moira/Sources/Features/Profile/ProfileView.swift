import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    infoRow("Version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                    infoRow("Data source", appState.searchServiceStatus.rawValue)
                    infoRow("Storage", "SwiftData local-first")
                }

                Section("Source status") {
                    Text(googleStatusLine)
                    Text(yelpStatusLine)
                    Text("Beli: manual input only in v1")
                }

                Section("Recently viewed") {
                    Button("Clear recently viewed", role: .destructive) {
                        appState.clearRecentlyViewed()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private var googleStatusLine: String {
        switch appState.searchServiceStatus {
        case .live:
            "Google Places: proxy-backed search is configured"
        case .notConfigured:
            "Google Places: unavailable until the proxy base URL is set"
        case .proxyUnavailable:
            "Google Places: last proxy request failed"
        }
    }

    private var yelpStatusLine: String {
        switch appState.searchServiceStatus {
        case .live:
            "Yelp Match: fetched through the proxy on place detail refresh"
        case .notConfigured:
            "Yelp Match: unavailable until the proxy base URL is set"
        case .proxyUnavailable:
            "Yelp Match: last proxy lookup failed gracefully"
        }
    }
}
