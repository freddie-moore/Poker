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

    /// Splits each player's stack (buy-in minus reserve) across the available
    /// chip colors. Colors are assigned denominations smallest-first, in the
    /// order given. Returns nil if no exact split exists.
    static func calculate(stackValue: Double, playerCount: Int, colors: [(name: String, count: Int)]) -> [ChipDenomination]? {
        guard stackValue > 0, playerCount > 0 else { return nil }
        let target = Int((stackValue * 100).rounded())
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
        let r = calculate(stackValue: 10, playerCount: 4, colors: colors)!
        let total = r.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        assert(abs(total - 10) < 0.001, "split must equal stack value")
        assert(zip(r, r.dropFirst()).allSatisfy { $0.denomination < $1.denomination })
        assert(zip(r, r.dropFirst()).allSatisfy { $0.perPlayer >= $1.perPlayer }, "pyramid shape")
        assert(r.allSatisfy { $0.perPlayer <= 12 }, "respects availability")
        // Impossible: £0.01 can't be made from 5p chips
        assert(calculate(stackValue: 0.01, playerCount: 1, colors: colors) == nil)
    }
}
#endif
