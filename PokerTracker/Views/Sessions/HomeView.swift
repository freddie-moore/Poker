import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]
    @State private var showingSetup = false
    @State private var activeSession: GameSession?

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "suit.club.fill",
                    description: Text("Start a new session to begin tracking")
                )
            } else {
                List {
                    let active = sessions.filter { $0.status == .active }
                    let completed = sessions.filter { $0.status == .completed }

                    if !active.isEmpty {
                        Section("Active") {
                            ForEach(active) { session in
                                SessionRow(session: session)
                                    .contentShape(Rectangle())
                                    .onTapGesture { activeSession = session }
                            }
                        }
                    }

                    if !completed.isEmpty {
                        Section("Completed") {
                            ForEach(completed) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSetup = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            SessionSetupView()
        }
        .sheet(item: $activeSession) { session in
            ActiveSessionView(session: session)
        }
    }
}

private struct SessionRow: View {
    let session: GameSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date, format: .dateTime.weekday(.wide).day().month())
                    .font(.headline)
                Spacer()
                StatusBadge(status: session.status)
            }
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                    .foregroundStyle(.secondary)
                Text("\(session.participants.count) players")
                Text("•")
                Text("Pot: \(session.totalPot.formatted(.currency(code: "GBP")))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Player chips
            HStack(spacing: -8) {
                ForEach(session.participants.prefix(6)) { sp in
                    if let player = sp.player {
                        PlayerChip(name: player.name, colorHex: player.colorHex, size: 28)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    }
                }
                if session.participants.count > 6 {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 28, height: 28)
                        .overlay(Text("+\(session.participants.count - 6)").font(.system(size: 10)).foregroundStyle(.secondary))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status == .active ? "Live" : "Done")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status == .active ? Color.green.opacity(0.2) : Color.secondary.opacity(0.15))
            .foregroundStyle(status == .active ? .green : .secondary)
            .clipShape(Capsule())
    }
}
