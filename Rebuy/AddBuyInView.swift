import SwiftUI

struct AddBuyInView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var amount: String
    @Binding var buyInType: BuyInType
    let onSave: () -> Void
    
    var isAmountValid: Bool {
        guard let value = Double(amount) else { return false }
        return value > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Buy-in Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Type")) {
                    Picker("Buy-in Type", selection: $buyInType) {
                        Text("Initial").tag(BuyInType.initial)
                        Text("Rebuy").tag(BuyInType.rebuy)
                        Text("Add-on").tag(BuyInType.addOn)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Buy-in")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if isAmountValid {
                        onSave()
                        dismiss()
                    }
                }
                .disabled(!isAmountValid)
            )
        }
    }
}

struct AddBuyInView_Previews: PreviewProvider {
    static var previews: some View {
        AddBuyInView(
            amount: .constant("50"),
            buyInType: .constant(.rebuy),
            onSave: {}
        )
    }
}

