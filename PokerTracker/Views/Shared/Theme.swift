import SwiftUI

enum Theme {
    // Casino felt green
    static let felt = Color(hex: "1B4332")
    // Rich gold for primary actions / highlights
    static let gold = Color(hex: "C9A84C")
    // Deep background
    static let background = Color(hex: "0D1117")
    // Card surface
    static let surface = Color(hex: "161B22")
    // Subtle border
    static let border = Color(hex: "30363D")

    static let win = Color(hex: "2ECC71")
    static let lose = Color(hex: "E74C3C")
}

// Casino-appropriate chip colours for players
let playerColors: [String] = [
    "E74C3C", // red
    "3498DB", // blue
    "2ECC71", // green
    "F0C040", // gold
    "9B59B6", // purple
    "E67E22", // orange
    "1ABC9C", // teal
    "E91E63", // pink
]
