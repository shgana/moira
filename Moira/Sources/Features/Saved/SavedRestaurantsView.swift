import SwiftUI
import SwiftData

struct SavedRestaurantsView: View {
    @Query(sort: \Restaurant.updatedAt, order: .reverse) private var restaurants: [Restaurant]
    @State private var status: ListStatus = .wantToTry
    @State private var filter = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Status", selection: $status) {
                        ForEach(ListStatus.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Filter saved restaurants", text: $filter)
                        .textFieldStyle(.roundedBorder)

                    if filteredRestaurants.isEmpty {
                        Text("Nothing here yet.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .moiraCard()
                    } else {
                        ForEach(filteredRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantRowView(restaurant: restaurant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(MoiraTheme.background.ignoresSafeArea())
            .navigationTitle("Saved")
        }
    }

    private var filteredRestaurants: [Restaurant] {
        restaurants.filter { restaurant in
            restaurant.listStatus == status
                && (filter.isEmpty
                    || restaurant.name.localizedCaseInsensitiveContains(filter)
                    || restaurant.cuisine.localizedCaseInsensitiveContains(filter)
                    || restaurant.city.localizedCaseInsensitiveContains(filter))
        }
    }
}
