import SwiftUI

struct CashOutSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sessionPlayer: SessionPlayer

    @State private var finalAmount: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if let player = sessionPlayer.player {
                            PlayerChip(name: player.name, colorHex: player.colorHex, size: 44)
                        }
                        VStack(alignment: .leading) {
                            Text(sessionPlayer.displayName)
                                .font(.headline)
                            Text("Total in: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Final Chip Count") {
                    HStack {
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("Amount", value: $finalAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                if finalAmount > 0 {
                    Section {
                        let net = finalAmount - sessionPlayer.totalBuyIn
                        HStack {
                            Text("Net result")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(net >= 0 ? "+\(net.formatted(.currency(code: "GBP")))" : net.formatted(.currency(code: "GBP")))
                                .fontWeight(.semibold)
                                .foregroundStyle(net >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Cash Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { confirm() }
                        .disabled(finalAmount < 0)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func confirm() {
        sessionPlayer.finalAmount = finalAmount
        sessionPlayer.cashedOutAt = Date()
        dismiss()
    }
}
