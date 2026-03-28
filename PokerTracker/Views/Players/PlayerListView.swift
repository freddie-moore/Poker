import SwiftUI
import SwiftData

struct PlayerListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]

    @State private var showingAddPlayer = false
    @State private var playerToEdit: Player?

    var body: some View {
        Group {
            if players.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.gold.opacity(0.4))
                    Text("No Players")
                        .font(.title3.bold())
                    Text("Add players to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(players) { player in
                        Button {
                            playerToEdit = player
                        } label: {
                            PlayerRow(player: player)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deletePlayers)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Players")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPlayer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            PlayerFormView()
        }
        .sheet(item: $playerToEdit) { player in
            PlayerDetailView(player: player)
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        for index in offsets {
            context.delete(players[index])
        }
    }
}

private struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            PlayerChip(name: player.name, colorHex: player.colorHex)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.headline)
                Text("\(player.sessionsPlayed) sessions • \(player.winRate, format: .percent.precision(.fractionLength(0))) win rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(player.lifetimeNet, format: .currency(code: "GBP"))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(player.lifetimeNet >= 0 ? Theme.win : Theme.lose)
        }
        .padding(.vertical, 4)
    }
}
