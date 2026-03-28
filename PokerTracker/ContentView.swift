import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Sessions", systemImage: "suit.spade.fill")
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
                Label("Balances", systemImage: "chart.bar.fill")
            }
        }
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
    }
}
