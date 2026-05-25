import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    let searchService: AnyRestaurantSearchService

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            SearchHomeView(searchService: searchService)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(RootTab.search)

            SavedRestaurantsView()
                .tabItem { Label("Saved", systemImage: "square.grid.2x2") }
                .tag(RootTab.saved)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(RootTab.profile)
        }
        .tint(MoiraTheme.ink)
    }
}
