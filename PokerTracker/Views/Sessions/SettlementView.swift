import SwiftUI

struct SettlementView: View {
    let session: GameSession

    private var balances: [Player: Double] {
        SettlementCalculator.sessionBalances(session: session)
    }

    private var transfers: [Transfer] {
        SettlementCalculator.calculate(balances: balances)
    }

    var body: some View {
        List {
            Section("Session Results") {
                ForEach(
                    session.participants.sorted { ($0.netResult ?? 0) > ($1.netResult ?? 0) }
                ) { sp in
                    HStack(spacing: 12) {
                        if let player = sp.player {
                            PlayerChip(name: player.name, colorHex: player.colorHex, size: 36)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sp.displayName).font(.subheadline)
                            Text("Bought in: \(sp.totalBuyIn.formatted(.currency(code: "GBP")))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let net = sp.netResult {
                            Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundStyle(net >= 0 ? .green : .red)
                        }
                    }
                }
            }

            Section {
                if transfers.isEmpty {
                    Text("All square — no transfers needed!")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(transfers.enumerated()), id: \.offset) { _, transfer in
                        TransferRow(transfer: transfer)
                    }
                }
            } header: {
                Text("Settle Up")
            } footer: {
                Text("These are the minimum transfers needed to settle this session.")
                    .font(.caption)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TransferRow: View {
    let transfer: Transfer

    var body: some View {
        HStack(spacing: 10) {
            PlayerChip(name: transfer.from.name, colorHex: transfer.from.colorHex, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(transfer.from.name).fontWeight(.medium)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(transfer.to.name).fontWeight(.medium)
                }
                .font(.subheadline)
            }
            Spacer()
            Text(transfer.amount.formatted(.currency(code: "GBP")))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.blue)
            PlayerChip(name: transfer.to.name, colorHex: transfer.to.colorHex, size: 36)
        }
    }
}
