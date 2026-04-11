import SwiftUI
import SwiftData

@main
struct PokerTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Player.self, PlayerGroup.self, GameSession.self, SessionPlayer.self, BuyIn.self])
    }
}
