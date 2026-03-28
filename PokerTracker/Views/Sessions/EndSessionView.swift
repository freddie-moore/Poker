import SwiftUI

struct EndSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let session: GameSession

    // Final amounts keyed by SessionPlayer id for still-active players
    @State private var finalAmounts: [UUID: Double] = [:]
    @State private var isConfirmed = false

    private var activePlayers: [SessionPlayer] {
        session.participants
            .filter { $0.isActive }
            .sorted { $0.displayName < $1.displayName }
    }

    private var allEntered: Bool {
        activePlayers.allSatisfy { finalAmounts[$0.id] != nil }
    }

    var body: some View {
        Group {
            if isConfirmed {
                SettlementView(session: session)
            } else {
                inputView
            }
        }
        .navigationTitle("End Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputView: some View {
        Form {
            // Already cashed-out players shown for reference
            let cashedOut = session.participants.filter { !$0.isActive }
            if !cashedOut.isEmpty {
                Section("Already Cashed Out") {
                    ForEach(cashedOut.sorted { $0.displayName < $1.displayName }) { sp in
                        HStack {
                            if let player = sp.player {
                                PlayerChip(name: player.name, colorHex: player.colorHex, size: 32)
                            }
                            Text(sp.displayName)
                            Spacer()
                            if let net = sp.netResult {
                                Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                                    .foregroundStyle(net >= 0 ? .green : .red)
                                    .font(.subheadline.monospacedDigit())
                            }
                        }
                    }
                }
            }

            if !activePlayers.isEmpty {
                Section("Enter Final Chip Counts") {
                    ForEach(activePlayers) { sp in
                        HStack(spacing: 12) {
                            if let player = sp.player {
                                PlayerChip(name: player.name, colorHex: player.colorHex, size: 32)
                            }
                            Text(sp.displayName)
                                .frame(minWidth: 80, alignment: .leading)
                            Spacer()
                            HStack(spacing: 2) {
                                Text("£").foregroundStyle(.secondary)
                                TextField("0", value: Binding(
                                    get: { finalAmounts[sp.id] ?? 0 },
                                    set: { finalAmounts[sp.id] = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Calculate Results") {
                    applyFinalAmounts()
                }
                .frame(maxWidth: .infinity)
                .disabled(!allEntered && !activePlayers.isEmpty)
            }
        }
    }

    private func applyFinalAmounts() {
        for sp in activePlayers {
            sp.finalAmount = finalAmounts[sp.id] ?? 0
            sp.cashedOutAt = Date()
        }
        session.status = .completed
        isConfirmed = true
    }
}
