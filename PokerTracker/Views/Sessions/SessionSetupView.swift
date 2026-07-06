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

    @State private var bankReserve: Double = 0
    @AppStorage("chips.green") private var greenCount = 50
    @AppStorage("chips.red") private var redCount = 50
    @AppStorage("chips.black") private var blackCount = 50
    @AppStorage("chips.blue") private var blueCount = 50

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

                Section {
                    HStack {
                        Text("Reserve for re-buys")
                        Spacer()
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("0", value: $bankReserve, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    chipCountRow("Green", $greenCount)
                    chipCountRow("Red", $redCount)
                    chipCountRow("Black", $blackCount)
                    chipCountRow("Blue", $blueCount)
                } header: {
                    Text("Chips")
                } footer: {
                    Text("Each player is dealt chips worth the buy-in minus the reserve.")
                }

                Section("Chip Split (per player)") {
                    if selectedPlayerIDs.isEmpty {
                        Text("Select players to see the split.")
                            .foregroundStyle(.secondary)
                    } else if let split = chipSplit {
                        ForEach(split) { chip in
                            HStack {
                                chipCircle(chipColors[chip.colorName] ?? .gray)
                                Text("\(chip.colorName) — \(formatDenom(chip.denomination))")
                                Spacer()
                                Text("× \(chip.perPlayer)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No even split possible — adjust the reserve or chip counts.")
                            .foregroundStyle(.secondary)
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

    private let chipColors: [String: Color] = [
        "Green": .green, "Red": .red, "Black": .black, "Blue": .blue
    ]

    private var chipSplit: [ChipDenomination]? {
        ChipCalculator.calculate(
            stackValue: buyInAmount - bankReserve,
            playerCount: selectedPlayerIDs.count,
            colors: [
                ("Green", greenCount), ("Red", redCount),
                ("Black", blackCount), ("Blue", blueCount)
            ]
        )
    }

    private func chipCountRow(_ name: String, _ count: Binding<Int>) -> some View {
        HStack {
            chipCircle(chipColors[name] ?? .gray)
            Text(name)
            Spacer()
            TextField("50", value: count, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
        }
    }

    private func chipCircle(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().strokeBorder(.secondary.opacity(0.4), lineWidth: 1))
            .frame(width: 20, height: 20)
    }

    private func formatDenom(_ value: Double) -> String {
        value < 1 ? "\(Int((value * 100).rounded()))p" : "£\(value.formatted())"
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
