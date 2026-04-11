import SwiftUI
import SwiftData

struct AddPlayersToSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: GameSession

    @Query(sort: \Player.name) private var allPlayers: [Player]

    @State private var selectedPlayerIDs: Set<UUID> = []
    @State private var buyInAmount: Double

    init(session: GameSession) {
        self.session = session
        _buyInAmount = State(initialValue: session.initialBuyIn)
    }

    private var availablePlayers: [Player] {
        let existingIDs = Set(session.participants.compactMap { $0.player?.id })
        return allPlayers.filter { !existingIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buy-in Amount") {
                    HStack {
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("Amount", value: $buyInAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Players") {
                    if availablePlayers.isEmpty {
                        Text("All players are already in this session.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availablePlayers) { player in
                            AddPlayerRow(
                                player: player,
                                isSelected: selectedPlayerIDs.contains(player.id)
                            ) {
                                if selectedPlayerIDs.contains(player.id) {
                                    selectedPlayerIDs.remove(player.id)
                                } else {
                                    selectedPlayerIDs.insert(player.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addPlayers() }
                        .disabled(selectedPlayerIDs.isEmpty || buyInAmount <= 0)
                }
            }
        }
    }

    private func addPlayers() {
        let selected = availablePlayers.filter { selectedPlayerIDs.contains($0.id) }
        for player in selected {
            let sp = SessionPlayer(player: player, session: session)
            context.insert(sp)
            let buyIn = BuyIn(amount: buyInAmount, sessionPlayer: sp)
            context.insert(buyIn)
        }
        dismiss()
    }
}

private struct AddPlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlayerChip(name: player.name, colorHex: player.colorHex, size: 36)
            Text(player.name)
                .font(.body)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
