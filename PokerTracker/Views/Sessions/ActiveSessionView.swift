import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: GameSession

    @State private var playerForReBuy: SessionPlayer?
    @State private var playerForCashOut: SessionPlayer?
    @State private var showingEndSession = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Pot")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.totalPot.formatted(.currency(code: "GBP")))
                                .font(.title2.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Players")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(session.activePlayers.count) active")
                                .font(.title2.bold())
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Active Players") {
                    let active = session.participants
                        .filter { $0.isActive }
                        .sorted { $0.displayName < $1.displayName }

                    if active.isEmpty {
                        Text("All players have cashed out")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(active) { sp in
                            PlayerSessionCard(sessionPlayer: sp) {
                                playerForReBuy = sp
                            } onCashOut: {
                                playerForCashOut = sp
                            }
                        }
                    }
                }

                let cashedOut = session.participants.filter { !$0.isActive }
                if !cashedOut.isEmpty {
                    Section("Cashed Out") {
                        ForEach(cashedOut.sorted { $0.displayName < $1.displayName }) { sp in
                            CashedOutRow(sessionPlayer: sp)
                        }
                    }
                }
            }
            .navigationTitle("Live Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("End Session") {
                        showingEndSession = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .sheet(item: $playerForReBuy) { sp in
                ReBuySheet(sessionPlayer: sp)
            }
            .sheet(item: $playerForCashOut) { sp in
                CashOutSheet(sessionPlayer: sp)
            }
            .navigationDestination(isPresented: $showingEndSession) {
                EndSessionView(session: session)
            }
        }
    }
}

private struct PlayerSessionCard: View {
    let sessionPlayer: SessionPlayer
    let onReBuy: () -> Void
    let onCashOut: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                if let player = sessionPlayer.player {
                    PlayerChip(name: player.name, colorHex: player.colorHex, size: 44)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionPlayer.displayName)
                        .font(.headline)
                    Text("Total in: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if sessionPlayer.buyIns.count > 1 {
                        Text("\(sessionPlayer.buyIns.count) buy-ins")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    onReBuy()
                } label: {
                    Label("Re-buy", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onCashOut()
                } label: {
                    Label("Cash Out", systemImage: "dollarsign.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CashedOutRow: View {
    let sessionPlayer: SessionPlayer

    var body: some View {
        HStack(spacing: 12) {
            if let player = sessionPlayer.player {
                PlayerChip(name: player.name, colorHex: player.colorHex, size: 36)
                    .opacity(0.6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionPlayer.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Bought in: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let final = sessionPlayer.finalAmount {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(final.formatted(.currency(code: "GBP")))
                        .font(.subheadline.monospacedDigit())
                    if let net = sessionPlayer.netResult {
                        Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(net >= 0 ? .green : .red)
                    }
                }
            }
        }
    }
}
