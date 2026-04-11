import SwiftUI
import SwiftData

struct PlayerListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]
    @Query(sort: \PlayerGroup.name) private var groups: [PlayerGroup]

    @State private var showingAddPlayer = false
    @State private var showingAddGroup = false
    @State private var playerToEdit: Player?
    @State private var groupToEdit: PlayerGroup?
    @State private var selectedTab: PlayerTab = .players

    private enum PlayerTab: String, CaseIterable {
        case players = "Players"
        case groups = "Groups"
    }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(PlayerTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if selectedTab == .players {
                    playersContent
                } else {
                    groupsContent
                }
            }
        }
        .navigationTitle("Players")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedTab == .players {
                    Button { showingAddPlayer = true } label: {
                        Image(systemName: "plus")
                    }
                } else {
                    Button { showingAddGroup = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlayer) {
            PlayerFormView()
        }
        .sheet(isPresented: $showingAddGroup) {
            GroupFormView()
        }
        .sheet(item: $playerToEdit) { player in
            PlayerDetailView(player: player)
        }
        .sheet(item: $groupToEdit) { group in
            GroupFormView(group: group)
        }
    }

    @ViewBuilder
    private var playersContent: some View {
        if players.isEmpty {
            emptyState(
                icon: "person.badge.plus",
                title: "No Players",
                subtitle: "Add players to get started"
            )
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

    @ViewBuilder
    private var groupsContent: some View {
        if groups.isEmpty {
            emptyState(
                icon: "person.2.badge.plus",
                title: "No Groups",
                subtitle: "Create groups to quickly add players to a session"
            )
        } else {
            List {
                ForEach(groups) { group in
                    Button {
                        groupToEdit = group
                    } label: {
                        GroupRow(group: group)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteGroups)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.gold.opacity(0.4))
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func deletePlayers(at offsets: IndexSet) {
        for index in offsets {
            context.delete(players[index])
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            context.delete(groups[index])
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

private struct GroupRow: View {
    let group: PlayerGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(group.name)
                    .font(.headline)
                Spacer()
                Text("\(group.players.count) player\(group.players.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !group.players.isEmpty {
                HStack(spacing: -8) {
                    ForEach(group.players.prefix(8)) { player in
                        PlayerChip(name: player.name, colorHex: player.colorHex, size: 28)
                    }
                    if group.players.count > 8 {
                        Text("+\(group.players.count - 8)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
