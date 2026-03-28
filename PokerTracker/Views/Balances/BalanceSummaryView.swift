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
                ContentUnavailableView(
                    "No Balances",
                    systemImage: "dollarsign.circle",
                    description: Text("Complete a session to see balances")
                )
            } else {
                List {
                    Section("Running Balances") {
                        ForEach(sortedBalances, id: \.0.id) { player, balance in
                            HStack(spacing: 12) {
                                PlayerChip(name: player.name, colorHex: player.colorHex, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name).font(.headline)
                                    Text("\(player.sessionsPlayed) sessions")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(balance >= 0
                                     ? "+\(balance.formatted(.currency(code: "GBP")))"
                                     : balance.formatted(.currency(code: "GBP")))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .foregroundStyle(balance >= 0 ? .green : .red)
                            }
                        }
                    }

                    Section {
                        if transfers.isEmpty {
                            Text("All square — no transfers needed!")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(transfers.enumerated()), id: \.offset) { _, transfer in
                                TransferRow(transfer: transfer)
                            }
                        }
                    } header: {
                        Text("Minimum Transfers to Settle Up")
                    } footer: {
                        Text("Based on cumulative balances across all unsettled sessions.")
                            .font(.caption)
                    }

                    if !transfers.isEmpty {
                        Section {
                            Button(role: .destructive) {
                                showingSettleConfirm = true
                            } label: {
                                Label("Mark as Settled", systemImage: "checkmark.seal")
                                    .frame(maxWidth: .infinity)
                            }
                        } footer: {
                            Text("Resets running balances to zero once everyone has paid.")
                                .font(.caption)
                        }
                    }
                }
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
