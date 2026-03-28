import SwiftUI

struct CurrencyField: View {
    let title: String
    @Binding var value: Double
    var placeholder: String = "0.00"

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Text("£")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .focused($focused)
                .onChange(of: text) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                    if filtered != newValue { text = filtered }
                    value = Double(filtered) ?? 0
                }
                .onAppear {
                    if value > 0 {
                        text = String(format: "%.2f", value)
                    }
                }
        }
    }
}
