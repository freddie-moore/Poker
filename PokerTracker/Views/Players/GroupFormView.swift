import SwiftUI
import SwiftData

struct GroupFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Player.name) private var players: [Player]

    var group: PlayerGroup?

    @State private var name: String = ""
    @State private var selectedPlayerIDs: Set<UUID> = []

    private var isEditing: Bool { group != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("e.g. Wednesday Night Crew", text: $name)
                }

                Section("Members") {
                    if players.isEmpty {
                        Text("No players yet. Add players first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(players) { player in
                            GroupPlayerRow(
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
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let group {
                    name = group.name
                    selectedPlayerIDs = Set(group.players.map(\.id))
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let selected = players.filter { selectedPlayerIDs.contains($0.id) }

        if let group {
            group.name = trimmed
            group.players = selected
        } else {
            let newGroup = PlayerGroup(name: trimmed)
            newGroup.players = selected
            context.insert(newGroup)
        }
        dismiss()
    }
}

private struct GroupPlayerRow: View {
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
