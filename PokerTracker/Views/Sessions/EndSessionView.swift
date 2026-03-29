import SwiftUI

struct EndSessionView: View {
    let session: GameSession
    let onSessionComplete: () -> Void

    @State private var finalAmounts: [UUID: Double] = [:]
    @State private var showingSettlement = false
    @State private var showingMismatchAlert = false

    private var activePlayers: [SessionPlayer] {
        session.participants
            .filter { $0.isActive }
            .sorted { $0.displayName < $1.displayName }
    }

    // All fields are always "entered" once pre-populated; 0 is a valid value
    private var allEntered: Bool {
        activePlayers.allSatisfy { finalAmounts[$0.id] != nil }
    }

    private var reportedTotal: Double {
        let cashedOutTotal = session.participants
            .filter { !$0.isActive }
            .compactMap { $0.finalAmount }
            .reduce(0, +)
        let activeTotal = activePlayers.reduce(0) { $0 + (finalAmounts[$1.id] ?? 0) }
        return cashedOutTotal + activeTotal
    }

    private var discrepancy: Double {
        reportedTotal - session.totalPot
    }

    var body: some View {
        inputView
            .navigationTitle("End Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingSettlement) {
                SettlementView(session: session, onDone: onSessionComplete)
            }
            .onAppear {
                // Pre-populate with 0 so 0 is treated as a valid entered value
                for sp in activePlayers where finalAmounts[sp.id] == nil {
                    finalAmounts[sp.id] = 0
                }
            }
    }

    private var inputView: some View {
        Form {
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
                                    .foregroundStyle(net >= 0 ? Theme.win : Theme.lose)
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
                HStack {
                    Text("Total reported")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reportedTotal.formatted(.currency(code: "GBP")))
                        .monospacedDigit()
                }
                HStack {
                    Text("Total pot")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(session.totalPot.formatted(.currency(code: "GBP")))
                        .monospacedDigit()
                }
                if abs(discrepancy) > 0.01 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Discrepancy")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text((discrepancy >= 0 ? "+" : "") + discrepancy.formatted(.currency(code: "GBP")))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button("Calculate Results") {
                    if abs(discrepancy) > 0.01 {
                        showingMismatchAlert = true
                    } else {
                        applyFinalAmounts()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(!allEntered && !activePlayers.isEmpty)
            }
        }
        .alert("Totals Don't Match", isPresented: $showingMismatchAlert) {
            Button("Go Back & Fix", role: .cancel) {}
            Button("Proceed Anyway", role: .destructive) { applyFinalAmounts() }
        } message: {
            let diff = abs(discrepancy).formatted(.currency(code: "GBP"))
            let direction = discrepancy > 0 ? "more than" : "less than"
            Text("Reported totals are \(diff) \(direction) the pot (£\(session.totalPot.formatted())). Check the chip counts before confirming.")
        }
    }

    private func applyFinalAmounts() {
        for sp in activePlayers {
            sp.finalAmount = finalAmounts[sp.id] ?? 0
            sp.cashedOutAt = Date()
        }
        session.status = .completed
        showingSettlement = true
    }
}
