import Foundation
import SwiftData

enum SessionStatus: String, Codable {
    case active
    case completed
}

@Model
final class GameSession {
    var id: UUID
    var date: Date
    var status: SessionStatus
    var initialBuyIn: Double
    /// True once the group has settled up — excluded from running balance calculations
    var isSettled: Bool
    @Relationship(deleteRule: .cascade, inverse: \SessionPlayer.session)
    var participants: [SessionPlayer]

    init(initialBuyIn: Double) {
        self.id = UUID()
        self.date = Date()
        self.status = .active
        self.initialBuyIn = initialBuyIn
        self.isSettled = false
        self.participants = []
    }

    var totalPot: Double {
        participants.reduce(0) { $0 + $1.totalBuyIn }
    }

    var activePlayers: [SessionPlayer] {
        participants.filter { $0.isActive }
    }
}
