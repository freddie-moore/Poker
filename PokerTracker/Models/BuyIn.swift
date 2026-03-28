import Foundation
import SwiftData

@Model
final class BuyIn {
    var id: UUID
    var amount: Double
    var timestamp: Date
    var sessionPlayer: SessionPlayer?

    init(amount: Double, sessionPlayer: SessionPlayer) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = Date()
        self.sessionPlayer = sessionPlayer
    }
}
