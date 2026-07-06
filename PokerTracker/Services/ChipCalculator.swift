import Foundation

struct ChipDenomination: Identifiable {
    let colorName: String
    let denomination: Double // £ value of one chip
    let perPlayer: Int

    var id: String { colorName }
}

enum ChipCalculator {
    /// Standard denominations in pence.
    private static let ladder = [5, 10, 25, 50, 100, 200, 500, 1000, 2500, 5000]

    /// Splits the largest stack worth at most (buy-in − minReserve) across the
    /// available chip colors; whatever can't be dealt evenly stays in the bank
    /// on top of the minimum reserve. Sum the result to get the actual stack.
    static func calculate(buyIn: Double, minReserve: Double, playerCount: Int, colors: [(name: String, count: Int)]) -> [ChipDenomination]? {
        var target = Int(((buyIn - minReserve) * 100).rounded(.down))
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
        // search quantities constrained to a pyramid (more small chips than
        // big) and keep the split with the most chips on the table.
        // ponytail: brute force — search space is tiny (<100k iterations).
        for start in 0...(ladder.count - n) {
            let denoms = Array(ladder[start..<(start + n)])
            var quantities = [Int](repeating: 0, count: n)

            // Levels run largest denom → smallest; minQty enforces the pyramid
            // (each smaller denom gets at least as many chips as the one above).
            func search(_ level: Int, _ remaining: Int, _ minQty: Int, _ chips: Int) {
                if level == 0 {
                    // Smallest denom takes the exact remainder or the set fails.
                    guard remaining % denoms[0] == 0 else { return }
                    let q = remaining / denoms[0]
                    guard q >= minQty, q <= avail[0] else { return }
                    let total = chips + q
                    if best == nil || total > best!.chipTotal {
                        quantities[0] = q
                        best = (quantities, denoms, total)
                    }
                    return
                }
                let cap = min(avail[level], remaining / denoms[level])
                guard minQty <= cap else { return }
                for q in minQty...cap {
                    quantities[level] = q
                    search(level - 1, remaining - q * denoms[level], q, chips + q)
                }
            }
            search(n - 1, target, 0, 0)
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
        assert(zip(r, r.dropFirst()).allSatisfy { $0.perPlayer >= $1.perPlayer }, "pyramid shape")
        assert(r.allSatisfy { $0.perPlayer <= 12 }, "respects availability")
        // £10.03 target can't be made from 5p chips → deals £10, 3p extra to bank
        let s = calculate(buyIn: 20, minReserve: 9.97, playerCount: 4, colors: colors)!
        let dealt = s.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        assert(abs(dealt - 10) < 0.001, "rounds stack down to nearest dealable amount")
        // Nothing dealable at all
        assert(calculate(buyIn: 20, minReserve: 19.99, playerCount: 4, colors: colors) == nil)
    }
}
#endif
