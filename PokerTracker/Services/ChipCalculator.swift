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

    /// Ladder in £, for building denomination pickers.
    static var denominations: [Double] { ladder.map { Double($0) / 100 } }

    // ponytail: ~40 chips is a comfortable stack; tune if stacks feel fiddly
    private static let idealChipsPerPlayer = 40

    /// Splits the largest evenly-dealable stack at or below `stackValue`
    /// across the available chip colors; whatever can't be dealt stays in
    /// the bank. A color with a non-nil denomination keeps that value;
    /// the rest are chosen automatically. Sum the result for the actual stack.
    static func calculate(stackValue: Double, playerCount: Int, colors: [(name: String, count: Int, denomination: Double?)]) -> [ChipDenomination]? {
        var target = Int((stackValue * 100).rounded())
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
    private static func splitPence(_ target: Int, playerCount: Int, colors: [(name: String, count: Int, denomination: Double?)]) -> [ChipDenomination]? {
        guard target > 0, playerCount > 0 else { return nil }
        // Only colors with at least one chip per player are usable.
        let usable = colors.filter { $0.count / playerCount >= 1 }
        let n = usable.count
        guard n > 0 else { return nil }
        let avail = usable.map { $0.count / playerCount }
        let fixed: [Int?] = usable.map { $0.denomination.map { Int(($0 * 100).rounded()) } }

        // Candidate denomination assignments, aligned with `usable`.
        var candidates: [[Int]] = []
        if fixed.allSatisfy({ $0 == nil }) {
            // All auto: runs of consecutive standard denominations.
            for start in 0...(ladder.count - n) {
                candidates.append(Array(ladder[start..<(start + n)]))
            }
        } else {
            // Fill the auto slots with every ascending combination of ladder
            // values around the user's fixed choices. ponytail: ≤165 combos.
            let autoSlots = fixed.indices.filter { fixed[$0] == nil }
            func build(_ slot: Int, _ minIdx: Int, _ chosen: [Int]) {
                if slot == autoSlots.count {
                    var denoms = fixed.map { $0 ?? 0 }
                    for (i, s) in autoSlots.enumerated() { denoms[s] = chosen[i] }
                    candidates.append(denoms)
                    return
                }
                for idx in minIdx..<ladder.count {
                    build(slot + 1, idx + 1, chosen + [ladder[idx]])
                }
            }
            build(0, 0, [])
        }

        var best: (quantities: [Int], denoms: [Int], distance: Int)?

        for denoms in candidates {
            // Search in ascending-denomination order, then map back to colors.
            let order = denoms.indices.sorted { denoms[$0] < denoms[$1] }
            let d = order.map { denoms[$0] }
            let a = order.map { avail[$0] }
            // maxBelow[i] = most value the levels smaller than i can carry
            var maxBelow = [Int](repeating: 0, count: n)
            for i in 1..<n { maxBelow[i] = maxBelow[i - 1] + a[i - 1] * d[i - 1] }
            var q = [Int](repeating: 0, count: n)

            // Levels run largest denom → smallest; keep the exact split whose
            // chip count is closest to a comfortable stack.
            func search(_ level: Int, _ remaining: Int, _ chips: Int) {
                if level == 0 {
                    // Smallest denom takes the exact remainder or the set fails.
                    guard remaining % d[0] == 0 else { return }
                    let q0 = remaining / d[0]
                    guard q0 <= a[0] else { return }
                    q[0] = q0
                    // Prefer splits that use every color, all else being equal.
                    let unused = q.count { $0 == 0 }
                    let distance = abs(chips + q0 - idealChipsPerPlayer) + unused
                    if best == nil || distance < best!.distance {
                        var mapped = [Int](repeating: 0, count: n)
                        for (si, oi) in order.enumerated() { mapped[oi] = q[si] }
                        best = (mapped, denoms, distance)
                    }
                    return
                }
                let dl = d[level]
                // Take at least enough that the smaller denoms can cover the rest.
                let lo = max(0, (remaining - maxBelow[level] + dl - 1) / dl)
                let hi = min(a[level], remaining / dl)
                guard lo <= hi else { return }
                for qq in lo...hi {
                    q[level] = qq
                    search(level - 1, remaining - qq * dl, chips + qq)
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
        let colors: [(String, Int, Double?)] = [
            ("Green", 50, nil), ("Red", 50, nil), ("Black", 50, nil), ("Blue", 50, nil)
        ]
        func dealt(_ r: [ChipDenomination]) -> Double {
            r.reduce(0.0) { $0 + $1.denomination * Double($1.perPlayer) }
        }
        // £10 stack, 4 players → exact split within 12 chips per color
        let r = calculate(stackValue: 10, playerCount: 4, colors: colors)!
        assert(abs(dealt(r) - 10) < 0.001, "£10 splits exactly")
        assert(zip(r, r.dropFirst()).allSatisfy { $0.denomination < $1.denomination })
        assert(r.allSatisfy { $0.perPlayer <= 12 }, "respects availability")
        // Sensible defaults: a £20 buy-in shouldn't bottom out at 5p chips
        let sensible = calculate(stackValue: 20, playerCount: 2, colors: colors)!
        assert(sensible.first!.denomination >= 0.10, "no fiddly 5p chips for £20")
        // Fixed denomination is honored and the split stays exact
        let fixed = calculate(stackValue: 20, playerCount: 4, colors: [
            ("Green", 50, 1.0), ("Red", 50, nil), ("Black", 50, nil), ("Blue", 50, nil)
        ])!
        assert(fixed.first { $0.colorName == "Green" }!.denomination == 1.0)
        assert(abs(dealt(fixed) - 20) < 0.001)
        // Scarce chips: one chip per player worth the whole stack still works
        let scarce = calculate(stackValue: 20, playerCount: 4,
                               colors: colors.map { ($0.0, 4, nil) })!
        assert(abs(dealt(scarce) - 20) < 0.001, "big-chip-only split allowed")
        // £10.03 can't be made from 5p chips → deals £10, 3p stays in the bank
        let s = calculate(stackValue: 10.03, playerCount: 4, colors: colors)!
        assert(abs(dealt(s) - 10) < 0.001, "rounds stack down to nearest dealable amount")
        // Nothing dealable at all
        assert(calculate(stackValue: 0.01, playerCount: 4, colors: colors) == nil)
    }
}
#endif
