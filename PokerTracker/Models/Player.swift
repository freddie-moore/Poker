import Foundation
import SwiftData

@Model
final class Player: Hashable {
    static func == (lhs: Player, rhs: Player) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SessionPlayer.player)
    var sessionPlayers: [SessionPlayer]

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sessionPlayers = []
    }

    /// Net profit/loss across all completed sessions
    var lifetimeNet: Double {
        sessionPlayers
            .filter { $0.session?.status == .completed }
            .compactMap { $0.netResult }
            .reduce(0, +)
    }

    var sessionsPlayed: Int {
        sessionPlayers.filter { $0.session?.status == .completed }.count
    }

    var sessionsWon: Int {
        sessionPlayers
            .filter { $0.session?.status == .completed }
            .compactMap { $0.netResult }
            .filter { $0 > 0 }
            .count
    }

    var winRate: Double {
        guard sessionsPlayed > 0 else { return 0 }
        return Double(sessionsWon) / Double(sessionsPlayed)
    }

    var biggestWin: Double {
        sessionPlayers
            .compactMap { $0.netResult }
            .filter { $0 > 0 }
            .max() ?? 0
    }

    var biggestLoss: Double {
        sessionPlayers
            .compactMap { $0.netResult }
            .filter { $0 < 0 }
            .min() ?? 0
    }

    var avgBuyIn: Double {
        let completed = sessionPlayers.filter { $0.session?.status == .completed }
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0.0) { $0 + $1.totalBuyIn }
        return total / Double(completed.count)
    }
}
