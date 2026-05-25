import SwiftUI
import SwiftData

@main
struct MoiraApp: App {
    @State private var appState: AppState
    private let container: ModelContainer
    private let searchService: AnyRestaurantSearchService

    init() {
        let servicePackage = SearchServiceFactory.make()
        _appState = State(initialValue: AppState(searchServiceStatus: servicePackage.status))
        searchService = servicePackage.service

        do {
            let schema = Schema([Restaurant.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [configuration])
            if PreviewSeeder.shouldSeedDemoData {
                try PreviewSeeder.seedIfNeeded(in: container.mainContext)
            }
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(searchService: searchService)
                .environment(appState)
        }
        .modelContainer(container)
    }
}
