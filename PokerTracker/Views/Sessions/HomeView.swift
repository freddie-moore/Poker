import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]
    @State private var showingSetup = false
    @State private var activeSession: GameSession?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.gold.opacity(0.4))
                        Text("No Sessions Yet")
                            .font(.title3.bold())
                        Text("Tap + to start your first game")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .scrollContentBackground(.hidden)
                }
            }

            // FAB
            Button {
                showingSetup = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(Theme.gold)
                    .clipShape(Circle())
                    .shadow(color: Theme.gold.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Poker Tracker")
        .navigationBarTitleDisplayMode(.large)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date, format: .dateTime.weekday(.abbreviated).day().month().year())
                    .font(.headline)
                Spacer()
                StatusBadge(status: session.status)
            }

            HStack(spacing: 12) {
                Label(
                    "\(session.participants.count) players",
                    systemImage: "person.2"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Label(
                    "Pot: \(session.totalPot.formatted(.currency(code: "GBP")))",
                    systemImage: "dollarsign.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: -8) {
                ForEach(session.participants.prefix(6)) { sp in
                    if let player = sp.player {
                        PlayerChip(name: player.name, colorHex: player.colorHex, size: 28)
                            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                    }
                }
                if session.participants.count > 6 {
                    Circle()
                        .fill(Theme.border)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("+\(session.participants.count - 6)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        HStack(spacing: 4) {
            if status == .active {
                Circle()
                    .fill(Theme.win)
                    .frame(width: 6, height: 6)
            }
            Text(status == .active ? "Live" : "Finished")
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            status == .active
                ? Theme.win.opacity(0.15)
                : Theme.border.opacity(0.5)
        )
        .foregroundStyle(status == .active ? Theme.win : .secondary)
        .clipShape(Capsule())
    }
}
