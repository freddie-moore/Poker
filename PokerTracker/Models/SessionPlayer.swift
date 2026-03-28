import Foundation
import SwiftData

@Model
final class SessionPlayer {
    var id: UUID
    var player: Player?
    var session: GameSession?
    var finalAmount: Double?
    var cashedOutAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \BuyIn.sessionPlayer)
    var buyIns: [BuyIn]

    init(player: Player, session: GameSession) {
        self.id = UUID()
        self.player = player
        self.session = session
        self.buyIns = []
    }

    var totalBuyIn: Double {
        buyIns.reduce(0) { $0 + $1.amount }
    }

    var netResult: Double? {
        finalAmount.map { $0 - totalBuyIn }
    }

    var isActive: Bool {
        finalAmount == nil
    }

    var displayName: String {
        player?.name ?? "Unknown"
    }
}
