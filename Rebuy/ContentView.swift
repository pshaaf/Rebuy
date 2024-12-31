import SwiftUI

// Constants
struct Constants {
    static let venmoBlue = Color(red: 0.067, green: 0.482, blue: 0.847)
    static let cardRed = Color(red: 0.698, green: 0.132, blue: 0.132)
}

struct Checkbox: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .blue : .gray)
        }
    }
}

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var amount: Double
    var venmoStatus: Bool
    var chipCount: Double
}

class PokerGameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var buyInText: String = ""
    
    init() {
        self.players = [
            Player(name: "Player 1", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 2", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 3", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 4", amount: 0, venmoStatus: false, chipCount: 0)
        ]
    }
    
    var totalInPlay: Double {
        players.reduce(0) { $0 + $1.amount }
    }
    
    var totalChipCount: Double {
        players.reduce(0) { $0 + $1.chipCount }
    }
    
    func populateAmounts() {
        if let amount = Double(buyInText) {
            for index in players.indices {
                if players[index].amount == 0 {
                    players[index].amount = amount
                }
            }
        }
    }
    
    func addPlayer() {
        let amount = Double(buyInText) ?? 0
        let newPlayer = Player(
            name: "Player \(players.count + 1)",
            amount: amount,
            venmoStatus: false,
            chipCount: 0
        )
        players.append(newPlayer)
    }
    
    func resetGame() {
        buyInText = ""
        players = [
            Player(name: "Player 1", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 2", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 3", amount: 0, venmoStatus: false, chipCount: 0),
            Player(name: "Player 4", amount: 0, venmoStatus: false, chipCount: 0)
        ]
    }
    
    func removePlayer(_ player: Player) {
        if let index = players.firstIndex(of: player) {
            players.remove(at: index)
        }
    }
    
    func openVenmo() {
        if let url = URL(string: "venmo://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let appStoreURL = URL(string: "https://apps.apple.com/us/app/venmo/id351727428") {
                    UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PokerGameViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Title and subtitle
                VStack(spacing: 4) {
                    Text("Rebuy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.cardRed)
                    Text("Poker Tracker")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // Buy-In Field + Populate
                HStack(spacing: 8) {
                    Text("Buy-In: $")
                    TextField("0", text: $viewModel.buyInText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                    
                    Button("Populate") {
                        viewModel.populateAmounts()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding()
                
                // Totals
                VStack(spacing: 8) {
                    Text("Total In Play: $\(viewModel.totalInPlay, specifier: "%.2f")")
                        .font(.headline)
                    
                    HStack(spacing: 0) {
                        Text("Total Chip Count: ")
                            .font(.headline)
                        Text("$\(viewModel.totalChipCount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(viewModel.totalChipCount == viewModel.totalInPlay ? .green : .red)
                    }
                }
                .padding(.bottom, 20)
                
                // The combined table
                // Outer ScrollView: vertical scrolling
                ScrollView(.vertical, showsIndicators: true) {
                    
                    // HStack: pinned "Player" column on left + horizontally scrollable columns on right
                    HStack(spacing: 0) {
                        
                        // LEFT (Pinned) COLUMN
                        VStack(spacing: 0) {
                            // Header for "Player"
                            Text("Player")
                                .font(.headline)
                                .frame(width: 100, alignment: .leading)
                                .padding(.vertical, 8)
                            
                            // Data rows for "Player"
                            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, _ in
                                TextField("Name", text: $viewModel.players[index].name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // RIGHT (Horizontally scrollable) columns
                        ScrollView(.horizontal, showsIndicators: true) {
                            VStack(spacing: 0) {
                                
                                // HEADER row for the other columns
                                HStack(spacing: 0) {
                                    Text("Amount")
                                        .font(.headline)
                                        .frame(width: 80, alignment: .leading)
                                    Text("Venmo")
                                        .font(.headline)
                                        .frame(width: 60, alignment: .center)
                                    Text("Chips")
                                        .font(.headline)
                                        .frame(width: 80, alignment: .leading)
                                    Text("P/L")
                                        .font(.headline)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    // Trash column header (could label "Del" if you want)
                                    Text("")
                                        .font(.headline)
                                        .frame(width: 40, alignment: .center)
                                }
                                .padding(.vertical, 8)
                                
                                // DATA rows for the other columns
                                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, p in
                                    HStack(spacing: 0) {
                                        // Amount
                                        TextField("Amount", value: $viewModel.players[index].amount,
                                                  format: .currency(code: "USD"))
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .frame(width: 80)
                                        
                                        // Venmo
                                        Checkbox(isChecked: $viewModel.players[index].venmoStatus)
                                            .frame(width: 60)
                                        
                                        // Chips
                                        TextField("Chips", value: $viewModel.players[index].chipCount,
                                                  format: .currency(code: "USD"))
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .frame(width: 80)
                                        
                                        // P/L
                                        let profitLoss = viewModel.players[index].chipCount
                                            - viewModel.players[index].amount
                                        Text(profitLoss.formatted(.currency(code: "USD")))
                                            .frame(width: 80, alignment: .leading)
                                            .foregroundColor(profitLoss >= 0 ? .green : .red)
                                        
                                        // Trash button
                                        Button {
                                            viewModel.removePlayer(p)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .frame(width: 40, alignment: .center)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {
                            viewModel.addPlayer()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Player")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.resetGame()
                        }) {
                            Text("Reset Game")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        viewModel.openVenmo()
                    }) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                            Text("Go to Venmo")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Constants.venmoBlue)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
