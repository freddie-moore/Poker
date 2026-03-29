import SwiftUI

struct PlayerDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let player: Player
    @State private var showingEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            PlayerChip(name: player.name, colorHex: player.colorHex, size: 72)
                            Text(player.name)
                                .font(.title2.bold())
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Lifetime Stats") {
                    StatRow(label: "Sessions Played", value: "\(player.sessionsPlayed)")
                    StatRow(label: "Win Rate", value: player.winRate.formatted(.percent.precision(.fractionLength(0))))
                    StatRow(
                        label: "Net Profit / Loss",
                        value: player.lifetimeNet.formatted(.currency(code: "GBP")),
                        valueColor: player.lifetimeNet >= 0 ? .green : .red
                    )
                    StatRow(label: "Biggest Win", value: player.biggestWin.formatted(.currency(code: "GBP")), valueColor: .green)
                    StatRow(label: "Biggest Loss", value: player.biggestLoss.formatted(.currency(code: "GBP")), valueColor: .red)
                    StatRow(label: "Avg Buy-in", value: player.avgBuyIn.formatted(.currency(code: "GBP")))
                    StatRow(
                        label: "Current Streak",
                        value: player.currentWinStreak > 0 ? "🔥 \(player.currentWinStreak)" : "\(player.currentWinStreak)",
                        valueColor: player.currentWinStreak > 0 ? Theme.win : .secondary
                    )
                    StatRow(label: "Best Streak", value: "\(player.bestWinStreak) wins")
                }

                Section("Session History") {
                    let completed = player.sessionPlayers
                        .filter { $0.session?.status == .completed }
                        .sorted { ($0.session?.date ?? .distantPast) > ($1.session?.date ?? .distantPast) }

                    if completed.isEmpty {
                        Text("No completed sessions")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(completed) { sp in
                            SessionHistoryRow(sessionPlayer: sp)
                        }
                    }
                }
            }
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEdit) {
                PlayerFormView(editingPlayer: player)
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
    }
}

private struct SessionHistoryRow: View {
    let sessionPlayer: SessionPlayer

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionPlayer.session?.date ?? Date(), format: .dateTime.day().month().year())
                    .font(.subheadline)
                Text("Buy-in: \((sessionPlayer.totalBuyIn).formatted(.currency(code: "GBP")))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let net = sessionPlayer.netResult {
                Text(net.formatted(.currency(code: "GBP")))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(net >= 0 ? .green : .red)
            }
        }
    }
}
