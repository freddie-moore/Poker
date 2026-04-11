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
    @Relationship(inverse: \PlayerGroup.players)
    var groups: [PlayerGroup]

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sessionPlayers = []
        self.groups = []
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

    /// Sessions sorted oldest → newest
    private var completedByDate: [SessionPlayer] {
        sessionPlayers
            .filter { $0.session?.status == .completed }
            .sorted { ($0.session?.date ?? .distantPast) < ($1.session?.date ?? .distantPast) }
    }

    /// Current active win streak (consecutive wins from most recent session backwards)
    var currentWinStreak: Int {
        var streak = 0
        for sp in completedByDate.reversed() {
            guard let net = sp.netResult else { break }
            if net > 0 { streak += 1 } else { break }
        }
        return streak
    }

    /// Best win streak across all sessions
    var bestWinStreak: Int {
        var best = 0
        var current = 0
        for sp in completedByDate {
            if (sp.netResult ?? 0) > 0 {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
}
