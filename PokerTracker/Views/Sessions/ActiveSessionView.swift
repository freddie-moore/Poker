import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: GameSession

    @Query private var participants: [SessionPlayer]

    @State private var playerForReBuy: SessionPlayer?
    @State private var playerForCashOut: SessionPlayer?
    @State private var showingEndSession = false
    @State private var showingAddPlayers = false

    init(session: GameSession) {
        self.session = session
        let id = session.id
        _participants = Query(filter: #Predicate<SessionPlayer> { sp in
            sp.session?.id == id
        })
    }

    private var active: [SessionPlayer] {
        participants.filter { $0.isActive }.sorted { $0.displayName < $1.displayName }
    }

    private var cashedOut: [SessionPlayer] {
        participants.filter { !$0.isActive }.sorted { $0.displayName < $1.displayName }
    }

    private var totalPot: Double {
        participants.reduce(0) { $0 + $1.totalBuyIn }
    }

    var body: some View {
        NavigationStack {
            List {
                // Pot summary card
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Pot")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(totalPot.formatted(.currency(code: "GBP")))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.gold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(active.count)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("At the Table") {
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

                if !cashedOut.isEmpty {
                    Section("Cashed Out") {
                        ForEach(cashedOut) { sp in
                            CashedOutRow(sessionPlayer: sp)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
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
                    .foregroundStyle(Theme.lose)
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingAddPlayers = true
                    } label: {
                        Label("Add Players", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(item: $playerForReBuy) { sp in
                ReBuySheet(sessionPlayer: sp)
            }
            .sheet(item: $playerForCashOut) { sp in
                CashOutSheet(sessionPlayer: sp)
            }
            .navigationDestination(isPresented: $showingEndSession) {
                EndSessionView(session: session, onSessionComplete: { dismiss() })
            }
            .sheet(isPresented: $showingAddPlayers) {
                AddPlayersToSessionSheet(session: session)
            }
        }
    }
}

private struct PlayerSessionCard: View {
    let sessionPlayer: SessionPlayer
    let onReBuy: () -> Void
    let onCashOut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let player = sessionPlayer.player {
                    PlayerChip(name: player.name, colorHex: player.colorHex, size: 48)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(sessionPlayer.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text("In: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(sessionPlayer.buyIns.count) buy-in\(sessionPlayer.buyIns.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Theme.gold.opacity(0.8))
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onReBuy) {
                    Label("Re-buy", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
                .tint(Theme.gold)

                Button(action: onCashOut) {
                    Label("Cash Out", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.win)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct CashedOutRow: View {
    let sessionPlayer: SessionPlayer

    var body: some View {
        HStack(spacing: 12) {
            if let player = sessionPlayer.player {
                PlayerChip(name: player.name, colorHex: player.colorHex, size: 36)
                    .opacity(0.5)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionPlayer.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("In: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let final = sessionPlayer.finalAmount, let net = sessionPlayer.netResult {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(final.formatted(.currency(code: "GBP")))
                        .font(.subheadline.monospacedDigit())
                    Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(net >= 0 ? Theme.win : Theme.lose)
                }
            }
        }
    }
}
