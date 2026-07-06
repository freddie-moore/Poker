import Foundation

struct ChipDenomination: Identifiable {
    let colorName: String
    let denomination: Double // £ value of one chip
    let perPlayer: Int

    var id: String { colorName }
}

enum ChipCalculator {
    /// Standard denominations in pence.
    private static let ladder = [5, 10, 25, 50, 100, 200, 500, 1000, 2000, 2500, 5000]

    /// Splits the largest stack worth at most (buy-in − minReserve) across the
    /// available chip colors; whatever can't be dealt evenly stays in the bank
    /// on top of the minimum reserve. Sum the result to get the actual stack.
    static func calculate(buyIn: Double, minReserve: Double, playerCount: Int, colors: [(name: String, count: Int)]) -> [ChipDenomination]? {
        // Round each side to pence first — subtracting Doubles can land a hair
        // under the true value and lose a whole 5p step.
        var target = Int((buyIn * 100).rounded()) - Int((minReserve * 100).rounded())
        target -= target % ladder[0] // only multiples of the smallest denom are dealable
        while target > 0 {
            if let split = splitPence(target, playerCount: playerCount, colors: colors) {
                return split
            }
            target -= ladder[0]
        }
        return nil
    }

    /// Exact split of `target` pence per player, or nil if impossible.
    private static func splitPence(_ target: Int, playerCount: Int, colors: [(name: String, count: Int)]) -> [ChipDenomination]? {
        guard target > 0, playerCount > 0 else { return nil }
        // Only colors with at least one chip per player are usable.
        let usable = colors.filter { $0.count / playerCount >= 1 }
        let n = usable.count
        guard n > 0 else { return nil }
        let avail = usable.map { $0.count / playerCount }

        var best: (quantities: [Int], denoms: [Int], chipTotal: Int)?

        // Try every run of n consecutive standard denominations; within each,
        // search all quantity combinations and keep the split with the most
        // chips on the table (which naturally favors small denominations).
        // ponytail: brute force — the bound prune keeps it well under 100k steps.
        for start in 0...(ladder.count - n) {
            let denoms = Array(ladder[start..<(start + n)])
            // maxBelow[i] = most value the levels smaller than i can carry
            var maxBelow = [Int](repeating: 0, count: n)
            for i in 1..<n { maxBelow[i] = maxBelow[i - 1] + avail[i - 1] * denoms[i - 1] }
            var quantities = [Int](repeating: 0, count: n)

            // Levels run largest denom → smallest.
            func search(_ level: Int, _ remaining: Int, _ chips: Int) {
                if level == 0 {
                    // Smallest denom takes the exact remainder or the set fails.
                    guard remaining % denoms[0] == 0 else { return }
                    let q = remaining / denoms[0]
                    guard q <= avail[0] else { return }
                    let total = chips + q
                    if best == nil || total > best!.chipTotal {
                        quantities[0] = q
                        best = (quantities, denoms, total)
                    }
                    return
                }
                let d = denoms[level]
                // Take at least enough that the smaller denoms can cover the rest.
                let lo = max(0, (remaining - maxBelow[level] + d - 1) / d)
                let hi = min(avail[level], remaining / d)
                guard lo <= hi else { return }
                for q in lo...hi {
                    quantities[level] = q
                    search(level - 1, remaining - q * d, chips + q)
                }
            }
            search(n - 1, target, 0)
        }

        guard let best else { return nil }
        return usable.indices.map { i in
            ChipDenomination(
                colorName: usable[i].name,
                denomination: Double(best.denoms[i]) / 100,
                perPlayer: best.quantities[i]
            )
        }
    }
}

#if DEBUG
extension ChipCalculator {
    static func selfCheck() {
        let colors = [("Green", 50), ("Red", 50), ("Black", 50), ("Blue", 50)]
        // £10 stack, 4 players → exact split within 12 chips per color
        let r = calculate(buyIn: 20, minReserve: 10, playerCount: 4, colors: colors)!
        let total = r.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        assert(abs(total - 10) < 0.001, "£10 splits exactly")
        assert(zip(r, r.dropFirst()).allSatisfy { $0.denomination < $1.denomination })
        assert(r.allSatisfy { $0.perPlayer <= 12 }, "respects availability")
        // Full buy-in dealt when there's no reserve
        let full = calculate(buyIn: 20, minReserve: 0, playerCount: 4, colors: colors)!
        assert(abs(full.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) } - 20) < 0.001)
        // Scarce chips: one chip per player worth the whole stack still works
        let scarce = calculate(buyIn: 20, minReserve: 0, playerCount: 4,
                               colors: colors.map { ($0.0, 4) })!
        let scarceTotal = scarce.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        assert(abs(scarceTotal - 20) < 0.001, "big-chip-only split allowed")
        // £10.03 target can't be made from 5p chips → deals £10, 3p extra to bank
        let s = calculate(buyIn: 20, minReserve: 9.97, playerCount: 4, colors: colors)!
        let dealt = s.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        assert(abs(dealt - 10) < 0.001, "rounds stack down to nearest dealable amount")
        // Nothing dealable at all
        assert(calculate(buyIn: 20, minReserve: 19.99, playerCount: 4, colors: colors) == nil)
    }
}
#endif
