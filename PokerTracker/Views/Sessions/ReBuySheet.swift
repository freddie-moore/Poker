import SwiftUI
import SwiftData

struct ReBuySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let sessionPlayer: SessionPlayer

    @State private var amount: Double = 0

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
                            Text("Already in: \(sessionPlayer.totalBuyIn.formatted(.currency(code: "GBP")))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Re-buy Amount") {
                    HStack {
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                if let initialBuyIn = sessionPlayer.session?.initialBuyIn {
                    Section {
                        Button("Use initial buy-in (£\(initialBuyIn.formatted()))") {
                            amount = initialBuyIn
                        }
                    }
                }
            }
            .navigationTitle("Re-buy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { confirm() }
                        .disabled(amount <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func confirm() {
        let buyIn = BuyIn(amount: amount, sessionPlayer: sessionPlayer)
        context.insert(buyIn)
        dismiss()
    }
}
