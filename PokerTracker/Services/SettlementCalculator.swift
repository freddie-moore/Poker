import Foundation

struct Transfer {
    let from: Player
    let to: Player
    let amount: Double
}

enum SettlementCalculator {
    /// Computes the minimum set of bank transfers to settle all balances.
    /// Positive balance = owed money (creditor), negative = owes money (debtor).
    static func calculate(balances: [Player: Double]) -> [Transfer] {
        var debtors: [(Player, Double)] = balances
            .filter { $0.value < -0.01 }
            .map { ($0.key, -$0.value) }
            .sorted { $0.1 > $1.1 }

        var creditors: [(Player, Double)] = balances
            .filter { $0.value > 0.01 }
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }

        var transfers: [Transfer] = []
        var di = 0
        var ci = 0

        while di < debtors.count && ci < creditors.count {
            let amount = min(debtors[di].1, creditors[ci].1)
            let rounded = (amount * 100).rounded() / 100
            if rounded > 0 {
                transfers.append(Transfer(from: debtors[di].0, to: creditors[ci].0, amount: rounded))
            }
            debtors[di].1 -= amount
            creditors[ci].1 -= amount
            if debtors[di].1 < 0.01 { di += 1 }
            if creditors[ci].1 < 0.01 { ci += 1 }
        }

        return transfers
    }

    /// Computes balances for a single completed session.
    static func sessionBalances(session: GameSession) -> [Player: Double] {
        var balances: [Player: Double] = [:]
        for sp in session.participants {
            guard let player = sp.player, let net = sp.netResult else { continue }
            balances[player, default: 0] += net
        }
        return balances
    }

    /// Computes cumulative balances across all completed sessions.
    static func allTimeBalances(sessions: [GameSession]) -> [Player: Double] {
        var balances: [Player: Double] = [:]
        for session in sessions where session.status == .completed {
            for sp in session.participants {
                guard let player = sp.player, let net = sp.netResult else { continue }
                balances[player, default: 0] += net
            }
        }
        return balances
    }
}
