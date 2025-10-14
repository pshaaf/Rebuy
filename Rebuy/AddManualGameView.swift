import SwiftUI

struct AddManualGameView: View {
    @Environment(\.dismiss) var dismiss
    let playerName: String
    @State private var profitLoss: String = ""
    @State private var selectedDate: Date = Date()
    let onSave: (Double, Date) -> Void
    
    var isAmountValid: Bool {
        guard let _ = Double(profitLoss) else { return false }
        // Allow any value including negative (for losses)
        return !profitLoss.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player")) {
                    Text(playerName)
                        .font(.headline)
                }
                
                Section(header: Text("Profit/Loss")) {
                    HStack {
                        Text("$")
                        TextField("Amount (+ or -)", text: $profitLoss)
                            .keyboardType(.decimalPad)
                    }
                    Text("Enter positive for profit, negative for loss")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Game Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Add Manual Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if isAmountValid, let amount = Double(profitLoss) {
                        onSave(amount, selectedDate)
                        dismiss()
                    }
                }
                .disabled(!isAmountValid)
            )
        }
    }
}

struct AddManualGameView_Previews: PreviewProvider {
    static var previews: some View {
        AddManualGameView(
            playerName: "John Doe",
            onSave: { _, _ in }
        )
    }
}

