import SwiftUI

struct SettlementView: View {
    let session: GameSession
    var onDone: (() -> Void)? = nil

    private var balances: [Player: Double] {
        SettlementCalculator.sessionBalances(session: session)
    }

    private var transfers: [Transfer] {
        SettlementCalculator.calculate(balances: balances)
    }

    var body: some View {
        List {
            // Winner / loser podium
            Section("Results") {
                ForEach(
                    session.participants.sorted { ($0.netResult ?? 0) > ($1.netResult ?? 0) }
                ) { sp in
                    HStack(spacing: 12) {
                        if let player = sp.player {
                            PlayerChip(name: player.name, colorHex: player.colorHex, size: 40)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sp.displayName).font(.subheadline.bold())
                            Text("Bought in \(sp.totalBuyIn.formatted(.currency(code: "GBP")))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let net = sp.netResult {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(sp.finalAmount?.formatted(.currency(code: "GBP")) ?? "—")
                                    .font(.subheadline.monospacedDigit())
                                Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(net >= 0 ? Theme.win : Theme.lose)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                if transfers.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.win)
                        Text("All square — no transfers needed!")
                    }
                } else {
                    ForEach(Array(transfers.enumerated()), id: \.offset) { _, transfer in
                        TransferRow(transfer: transfer)
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundStyle(Theme.gold)
                    Text("Settle Up")
                }
            } footer: {
                Text("Minimum transfers to settle this session.")
                    .font(.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(onDone != nil)
        .toolbar {
            if let onDone {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { onDone() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct TransferRow: View {
    let transfer: Transfer

    var body: some View {
        HStack(spacing: 12) {
            PlayerChip(name: transfer.from.name, colorHex: transfer.from.colorHex, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(transfer.from.name)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                    Text(transfer.to.name)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                Text("bank transfer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(transfer.amount.formatted(.currency(code: "GBP")))
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(Theme.gold)

            PlayerChip(name: transfer.to.name, colorHex: transfer.to.colorHex, size: 36)
        }
        .padding(.vertical, 2)
    }
}
