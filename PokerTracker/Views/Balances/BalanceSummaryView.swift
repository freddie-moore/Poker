import SwiftUI
import SwiftData

struct BalanceSummaryView: View {
    @Query private var allSessions: [GameSession]
    @State private var showingSettleConfirm = false

    private var unsettledCompleted: [GameSession] {
        allSessions.filter { $0.status == .completed && !$0.isSettled }
    }

    private var balances: [Player: Double] {
        SettlementCalculator.allTimeBalances(sessions: unsettledCompleted)
    }

    private var sortedBalances: [(Player, Double)] {
        balances.sorted { $0.value > $1.value }
    }

    private var transfers: [Transfer] {
        SettlementCalculator.calculate(balances: balances)
    }

    var body: some View {
        Group {
            if balances.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.gold.opacity(0.4))
                    Text("No Balances")
                        .font(.title3.bold())
                    Text("Complete a session to see running balances")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(sortedBalances, id: \.0.id) { player, balance in
                            HStack(spacing: 12) {
                                PlayerChip(name: player.name, colorHex: player.colorHex, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name).font(.headline)
                                    Text("\(player.sessionsPlayed) sessions")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(balance >= 0
                                     ? "+\(balance.formatted(.currency(code: "GBP")))"
                                     : balance.formatted(.currency(code: "GBP")))
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(balance >= 0 ? Theme.win : Theme.lose)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "chart.bar.fill").foregroundStyle(Theme.gold)
                            Text("Running Balances")
                        }
                    }

                    Section {
                        if transfers.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.win)
                                Text("All square — no transfers needed!")
                            }
                        } else {
                            ForEach(Array(transfers.enumerated()), id: \.offset) { _, transfer in
                                TransferRow(transfer: transfer)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundStyle(Theme.gold)
                            Text("Minimum Transfers")
                        }
                    } footer: {
                        Text("Based on cumulative balances across all unsettled sessions.")
                            .font(.caption)
                    }

                    if !transfers.isEmpty {
                        Section {
                            Button(role: .destructive) {
                                showingSettleConfirm = true
                            } label: {
                                Label("Mark All as Settled", systemImage: "checkmark.seal.fill")
                                    .frame(maxWidth: .infinity)
                            }
                        } footer: {
                            Text("Resets running balances to zero once everyone has paid.")
                                .font(.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Balances")
        .alert("Mark as Settled?", isPresented: $showingSettleConfirm) {
            Button("Settle Up", role: .destructive) { markSettled() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all running balances. Make sure everyone has paid before confirming.")
        }
    }

    private func markSettled() {
        for session in unsettledCompleted {
            session.isSettled = true
        }
    }
}
