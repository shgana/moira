import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var proxyURLInput: String = ""
    @State private var saveError: String?
    @FocusState private var proxyFieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    infoRow("Version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                    infoRow("Data source", appState.searchServiceStatus.rawValue)
                    infoRow("Storage", "SwiftData local-first")
                }

                Section {
                    TextField("https://your-proxy.vercel.app", text: $proxyURLInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($proxyFieldFocused)

                    HStack {
                        Button("Save") {
                            saveProxyURL()
                        }
                        .disabled(proxyURLInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        if appState.proxyBaseURL != nil {
                            Button("Clear", role: .destructive) {
                                clearProxyURL()
                            }
                        }
                    }

                    if let saveError {
                        Text(saveError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let url = appState.proxyBaseURL {
                        Text("Active: \(url.absoluteString)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No proxy URL set. Search and Google/Yelp refresh are disabled until you add one.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Proxy URL")
                } footer: {
                    Text("Use the HTTPS URL from your Vercel deployment (or an ngrok tunnel for local dev — iOS blocks plain http://localhost). Stored only on this device.")
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
            .onAppear {
                proxyURLInput = appState.proxyBaseURL?.absoluteString ?? ""
            }
        }
    }

    private func saveProxyURL() {
        saveError = nil
        let success = appState.setProxyBaseURL(proxyURLInput)
        if !success {
            saveError = "That doesn't look like a valid http(s) URL."
        } else {
            proxyFieldFocused = false
        }
    }

    private func clearProxyURL() {
        appState.setProxyBaseURL(nil)
        proxyURLInput = ""
        saveError = nil
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
            "Google Places: unavailable until the proxy URL is set"
        case .proxyUnavailable:
            "Google Places: last proxy request failed"
        }
    }

    private var yelpStatusLine: String {
        switch appState.searchServiceStatus {
        case .live:
            "Yelp Match: fetched through the proxy on place detail refresh"
        case .notConfigured:
            "Yelp Match: unavailable until the proxy URL is set"
        case .proxyUnavailable:
            "Yelp Match: last proxy lookup failed gracefully"
        }
    }
}
