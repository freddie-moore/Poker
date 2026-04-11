import Foundation
import SwiftData

@Model
final class PlayerGroup {
    var id: UUID
    var name: String
    var createdAt: Date
    var players: [Player]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.players = []
    }
}
