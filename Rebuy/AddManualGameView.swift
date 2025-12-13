import SwiftUI

struct AddManualGameView: View {
    @Environment(\.dismiss) var dismiss
    let playerName: String
    @State private var profitLoss: String = ""
    @State private var selectedDate: Date = Date()
    @State private var isProfit: Bool = true // true for profit, false for loss
    let onSave: (Double, Date) -> Void
    
    var isAmountValid: Bool {
        guard let amount = Double(profitLoss) else { return false }
        return !profitLoss.isEmpty && amount > 0
    }
    
    var computedAmount: Double {
        guard let amount = Double(profitLoss) else { return 0 }
        return isProfit ? amount : -amount
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player")) {
                    Text(playerName)
                        .font(.headline)
                }
                
                Section(header: Text("Profit/Loss")) {
                    HStack(spacing: 12) {
                        Button(action: {
                            isProfit = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Profit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isProfit ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(isProfit ? .green : .gray)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            isProfit = false
                        }) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                Text("Loss")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(!isProfit ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(!isProfit ? .red : .gray)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text(isProfit ? "+$" : "-$")
                            .foregroundColor(isProfit ? .green : .red)
                            .font(.headline)
                        TextField("Amount", text: $profitLoss)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.top, 4)
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
                    if isAmountValid {
                        onSave(computedAmount, selectedDate)
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

