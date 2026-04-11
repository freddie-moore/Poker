import SwiftUI
import SwiftData

struct SessionSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Player.name) private var players: [Player]
    @Query(sort: \PlayerGroup.name) private var groups: [PlayerGroup]

    @State private var selectedPlayerIDs: Set<UUID> = []
    @State private var buyInAmount: Double = 20
    @State private var showingNewPlayer = false
    @State private var navigateToSession: GameSession?

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

                if !groups.isEmpty {
                    Section("Groups") {
                        ForEach(groups) { group in
                            GroupSelectionRow(group: group) {
                                addAllFromGroup(group)
                            }
                        }
                    }
                }

                Section {
                    if players.isEmpty {
                        Text("No players yet. Add some first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(players) { player in
                            PlayerSelectionRow(
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
                } header: {
                    HStack {
                        Text("Players")
                        Spacer()
                        Button("Add New") { showingNewPlayer = true }
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { startSession() }
                        .disabled(selectedPlayerIDs.isEmpty || buyInAmount <= 0)
                }
            }
            .sheet(isPresented: $showingNewPlayer) {
                PlayerFormView()
            }
            .navigationDestination(item: $navigateToSession) { session in
                ActiveSessionView(session: session)
                    .navigationBarBackButtonHidden()
            }
        }
    }

    private func addAllFromGroup(_ group: PlayerGroup) {
        for player in group.players {
            selectedPlayerIDs.insert(player.id)
        }
    }

    private func startSession() {
        let session = GameSession(initialBuyIn: buyInAmount)
        context.insert(session)

        let selected = players.filter { selectedPlayerIDs.contains($0.id) }
        for player in selected {
            let sp = SessionPlayer(player: player, session: session)
            context.insert(sp)
            let buyIn = BuyIn(amount: buyInAmount, sessionPlayer: sp)
            context.insert(buyIn)
        }

        navigateToSession = session
    }
}

private struct GroupSelectionRow: View {
    let group: PlayerGroup
    let onAddAll: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.body)
                Text("\(group.players.count) player\(group.players.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Add All", action: onAddAll)
                .font(.caption.bold())
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(group.players.isEmpty)
        }
    }
}

private struct PlayerSelectionRow: View {
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
