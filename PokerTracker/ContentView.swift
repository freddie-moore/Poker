import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Sessions", systemImage: "suit.club.fill")
            }

            NavigationStack {
                PlayerListView()
            }
            .tabItem {
                Label("Players", systemImage: "person.2.fill")
            }

            NavigationStack {
                BalanceSummaryView()
            }
            .tabItem {
                Label("Balances", systemImage: "dollarsign.circle.fill")
            }
        }
    }
}
