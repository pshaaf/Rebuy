import SwiftUI

// Constants
struct Constants {
    static let venmoBlue = Color(red: 0.067, green: 0.482, blue: 0.847)
    static let cardRed = Color(red: 0.698, green: 0.132, blue: 0.132)
}

// Keyboard toolbar view
struct KeyboardToolbar: ToolbarContent {
    let action: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                action()
            }
        }
    }
}

// Extension to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                      to: nil, from: nil, for: nil)
    }
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
    var buyIns: [BuyIn]
    var venmoStatus: Bool
    var chipCount: Double
    
    var totalInvested: Double {
        return buyIns.reduce(0) { $0 + $1.amount }
    }
    
    var rebuyCount: Int {
        return buyIns.filter { $0.type != .initial }.count
    }
}

class PokerGameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var buyInText: String = ""
    @Published var showingEndGameAlert = false
    @Published var gameLogs: [GameLog] = []
    @Published var shouldShowLogs = false
    @Published var gameStartTime: Date?
    @Published var isGameActive: Bool = false
    @Published var currentTime: Date = Date() // For timer updates
    
    init() {
        self.players = [
            Player(name: "Player 1", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 2", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 3", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 4", buyIns: [], venmoStatus: false, chipCount: 0)
        ]
        
        // Load saved game logs
        if let savedLogs = UserDefaults.standard.data(forKey: "GameLogs"),
           let decodedLogs = try? JSONDecoder().decode([GameLog].self, from: savedLogs) {
            self.gameLogs = decodedLogs
        }
    }
    
    var totalInPlay: Double {
        players.reduce(0) { $0 + $1.totalInvested }
    }
    
    var totalChipCount: Double {
        players.reduce(0) { $0 + $1.chipCount }
    }
    
    var elapsedTime: TimeInterval {
        guard let startTime = gameStartTime else { return 0 }
        return currentTime.timeIntervalSince(startTime)
    }
    
    var formattedElapsedTime: String {
        let seconds = Int(elapsedTime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func startGame() {
        gameStartTime = Date()
        isGameActive = true
    }
    
    func stopGame() {
        isGameActive = false
    }
    
    // Function to update player name in game logs
    func updatePlayerName(in gameLog: GameLog, player: PlayerResult, newName: String) {
        if let gameIndex = gameLogs.firstIndex(where: { $0.id == gameLog.id }),
           let playerIndex = gameLogs[gameIndex].players.firstIndex(where: { $0.id == player.id }) {
            // Create a new array of players with the updated name
            var updatedPlayers = gameLogs[gameIndex].players
            updatedPlayers[playerIndex].name = newName
            
            // Create a new GameLog with the updated players
            let updatedLog = GameLog(
                id: gameLog.id,
                endDate: gameLog.endDate,
                duration: gameLog.duration,
                location: gameLog.location,
                players: updatedPlayers,
                totalBuyIn: gameLog.totalBuyIn,
                totalChipCount: gameLog.totalChipCount
            )
            
            // Update the gameLogs array
            gameLogs[gameIndex] = updatedLog
            saveGameLogs()
        }
    }
    
    // Function to create a game log
    private func createGameLog() -> GameLog {
        let playerResults = players.map { player in
            PlayerResult(
                name: player.name,
                buyIns: player.buyIns,
                finalChipCount: player.chipCount,
                venmoStatus: player.venmoStatus
            )
        }
        
        // Calculate duration if game was started
        let duration: Int? = {
            guard let startTime = gameStartTime else { return nil }
            return Int(Date().timeIntervalSince(startTime))
        }()
        
        return GameLog(
            duration: duration,
            players: playerResults,
            totalBuyIn: totalInPlay,
            totalChipCount: totalChipCount
        )
    }
    
    // Function to save game logs
    private func saveGameLogs() {
        if let encoded = try? JSONEncoder().encode(gameLogs) {
            UserDefaults.standard.set(encoded, forKey: "GameLogs")
        }
    }
    
    func populateAmounts() {
        if let amount = Double(buyInText), amount > 0 {
            for index in players.indices {
                if players[index].buyIns.isEmpty {
                    let initialBuyIn = BuyIn(amount: amount, type: .initial)
                    players[index].buyIns.append(initialBuyIn)
                }
            }
        }
    }
    
    func addBuyIn(for playerIndex: Int, amount: Double) {
        guard amount > 0, playerIndex < players.count else { return }
        
        // Auto-detect type: first buy-in is Initial, subsequent are Rebuy
        let type: BuyInType = players[playerIndex].buyIns.isEmpty ? .initial : .rebuy
        let newBuyIn = BuyIn(amount: amount, type: type)
        players[playerIndex].buyIns.append(newBuyIn)
    }
    
    func removeBuyIn(for playerIndex: Int, buyInId: UUID) {
        guard playerIndex < players.count else { return }
        players[playerIndex].buyIns.removeAll { $0.id == buyInId }
    }
    
    func addPlayer() {
        var buyIns: [BuyIn] = []
        if let amount = Double(buyInText), amount > 0 {
            buyIns = [BuyIn(amount: amount, type: .initial)]
        }
        let newPlayer = Player(
            name: "Player \(players.count + 1)",
            buyIns: buyIns,
            venmoStatus: false,
            chipCount: 0
        )
        players.append(newPlayer)
    }
    
    func endAndSaveGame() {
        stopGame()
        let newLog = createGameLog()
        gameLogs.append(newLog)
        saveGameLogs()
        resetGame()
        shouldShowLogs = true
    }
    
    func resetGame() {
        buyInText = ""
        gameStartTime = nil
        isGameActive = false
        players = [
            Player(name: "Player 1", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 2", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 3", buyIns: [], venmoStatus: false, chipCount: 0),
            Player(name: "Player 4", buyIns: [], venmoStatus: false, chipCount: 0)
        ]
    }
    
    func removePlayer(_ player: Player) {
        if let index = players.firstIndex(of: player) {
            players.remove(at: index)
        }
    }
    
    // Updated function to get stats for a specific player
    func getPlayerStats(for player: PlayerResult) -> PlayerStats {
        let playerName = player.name
        
        // Find all games this player participated in by name
        let gamesForPlayer = gameLogs.filter { gameLog in
            gameLog.players.contains { $0.name == playerName }
        }
        
        // Get all results for this player by name
        let playerResults = gamesForPlayer.compactMap { gameLog in
            gameLog.players.first { $0.name == playerName }
        }
        
        return PlayerStats(
            name: playerName,
            games: gamesForPlayer,
            playerResults: playerResults
        )
    }
    
    func getUniquePlayerNames() -> [String] {
        // Extract all player names from logs
        let allNames = gameLogs.flatMap { $0.players.map { $0.name } }
        
        // Create a unique set and sort alphabetically
        return Array(Set(allNames)).sorted()
    }
}

// Create a simple buy-in input component with its own focus state
struct BuyInInput: View {
    @Binding var text: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("0", text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .frame(width: 80)
            .focused($isFocused)
    }
}

// Create a new component for amount input with placeholder behavior
struct AmountInput: View {
    @Binding var amount: Double
    @State private var displayText = ""
    @FocusState private var isFocused: Bool
    
    var isDefaultAmount: Bool {
        return amount == 0
    }
    
    // Helper function to format amount with $ prefix
    private func formatAmount(_ value: Double) -> String {
        if value == 0 {
            return ""
        }
        return String(format: "$%.2f", value)
    }
    
    // Helper function to parse amount from text (removing $ and converting to Double)
    private func parseAmount(_ text: String) -> Double? {
        let cleanText = text.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleanText)
    }
    
    // Helper function to format user input with $ prefix
    private func formatUserInput(_ text: String) -> String {
        let cleanText = text.replacingOccurrences(of: "$", with: "")
        if cleanText.isEmpty {
            return ""
        }
        return "$" + cleanText
    }
    
    var body: some View {
        TextField(isDefaultAmount ? "$0.00" : "Amount", text: $displayText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .frame(width: 80)
            .foregroundColor(isDefaultAmount && !isFocused ? .gray : .primary)
            .onAppear {
                displayText = formatAmount(amount)
            }
            .onChange(of: amount) { newAmount in
                // Update displayText when amount changes externally (e.g., from populate button)
                if !isFocused {
                    displayText = formatAmount(newAmount)
                }
            }
            .onChange(of: isFocused) { focused in
                if focused {
                    // If focusing and it's a default amount, clear the display
                    if isDefaultAmount {
                        displayText = ""
                    } else {
                        // Remove $ for editing, but keep the number
                        if let value = parseAmount(displayText), value > 0 {
                            displayText = String(format: "%.2f", value)
                        }
                    }
                } else {
                    // If losing focus, save the entered amount and format with $
                    if let newAmount = parseAmount(displayText) {
                        amount = newAmount
                        displayText = formatAmount(newAmount)
                    } else if displayText.isEmpty {
                        // If empty, reset to 0
                        amount = 0
                        displayText = ""
                    }
                }
            }
            .onChange(of: displayText) { newValue in
                if isFocused && !newValue.isEmpty {
                    // Auto-add $ prefix if user starts typing without it
                    if !newValue.hasPrefix("$") && !newValue.isEmpty {
                        displayText = formatUserInput(newValue)
                    }
                    
                    // Update the binding with the parsed value
                    if let newAmount = parseAmount(newValue) {
                        amount = newAmount
                    }
                }
            }
            .focused($isFocused)
    }
}

// Create a new component for player name input with suggestions
struct PlayerNameInput: View {
    @Binding var name: String
    @ObservedObject var viewModel: PokerGameViewModel
    @State private var showSuggestions = false
    @State private var displayText = ""
    @FocusState private var isFocused: Bool
    var onFocus: (() -> Void)? = nil
    
    var isDefaultName: Bool {
        return name.hasPrefix("Player ") && name.count <= 8 // "Player X" format
    }
    
    var filteredSuggestions: [String] {
        if displayText.isEmpty {
            return []
        }
        
        return viewModel.getUniquePlayerNames().filter {
            $0.lowercased().contains(displayText.lowercased()) && $0.lowercased() != displayText.lowercased()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(isDefaultName ? name : "Name", text: $displayText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .foregroundColor(isDefaultName && !isFocused ? .gray : .primary)
                .onAppear {
                    displayText = isDefaultName ? "" : name
                }
                .onChange(of: isFocused) { focused in
                    if focused {
                        if let onFocus = onFocus {
                            onFocus()
                        }
                        // If focusing and it's a default name, clear the display
                        if isDefaultName {
                            displayText = ""
                        }
                    } else {
                        // If losing focus and display is empty, restore default name
                        if displayText.isEmpty && isDefaultName {
                            displayText = ""
                        } else if !displayText.isEmpty {
                            name = displayText
                        }
                    }
                    
                    showSuggestions = focused && !displayText.isEmpty && filteredSuggestions.count > 0
                }
                .onChange(of: displayText) { newValue in
                    if isFocused && !newValue.isEmpty {
                        name = newValue
                    }
                    showSuggestions = isFocused && !newValue.isEmpty && filteredSuggestions.count > 0
                }
            
            if showSuggestions && isFocused {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredSuggestions, id: \.self) { suggestion in
                            Text(suggestion)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    displayText = suggestion
                                    name = suggestion
                                    showSuggestions = false
                                    isFocused = false
                                }
                        }
                    }
                }
                .frame(height: min(CGFloat(filteredSuggestions.count * 35), 150))
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
                .zIndex(1) // Ensure suggestions appear above other content
            }
        }
    }
}

// Component for displaying buy-in chips
struct BuyInChipView: View {
    let buyIn: BuyIn
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(buyIn.amount.formatted(.currency(code: "USD")))
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(buyInTypeColor(buyIn.type))
        .cornerRadius(12)
    }
    
    private func buyInTypeColor(_ type: BuyInType) -> Color {
        switch type {
        case .initial: return .blue
        case .rebuy: return .orange
        case .addOn: return .purple
        }
    }
}

// Component for buy-ins display with horizontal scroll
struct BuyInsDisplay: View {
    let buyIns: [BuyIn]
    let playerIndex: Int
    let onAddBuyIn: () -> Void
    let onDeleteBuyIn: (UUID) -> Void
    
    var totalInvested: Double {
        buyIns.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Horizontal scrollable buy-in chips
                if !buyIns.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(buyIns) { buyIn in
                                BuyInChipView(buyIn: buyIn) {
                                    onDeleteBuyIn(buyIn.id)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 180)
                } else {
                    Text("No buy-ins")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 80)
                }
                
                // Add button
                Button(action: onAddBuyIn) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            // Total invested (bold)
            if !buyIns.isEmpty {
                Text("Total: \(totalInvested.formatted(.currency(code: "USD")))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 200, alignment: .leading)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PokerGameViewModel()
    @State private var keyboardVisible = false
    @State private var editingPlayerIndex: Int? = nil
    @State private var showingResetAlert = false
    @State private var showingAddBuyInSheet = false
    @State private var selectedPlayerIndex: Int? = nil
    @State private var buyInAmount: String = ""
    @State private var buyInType: BuyInType = .rebuy
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Title and header section - collapsed when keyboard is visible
                VStack(spacing: 4) {
                    if !keyboardVisible {
                        Text("Rebuy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.cardRed)
                        Text("Poker Tracker")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Buy-In Field + Populate - always visible
                    HStack(spacing: 8) {
                        Text("Buy-In: $")
                        BuyInInput(text: $viewModel.buyInText)
                        
                        Button("Populate") {
                            hideKeyboard()
                            viewModel.populateAmounts()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    // Timer section
                    if !keyboardVisible {
                        HStack(spacing: 12) {
                            if !viewModel.isGameActive {
                                Button(action: {
                                    viewModel.startGame()
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                        Text("Start Game")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(.blue)
                                    Text(viewModel.formattedElapsedTime)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    if !keyboardVisible {
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
                            
                            // Difference line
                            HStack(spacing: 0) {
                                Text("Difference: ")
                                    .font(.headline)
                                let difference = viewModel.totalChipCount - viewModel.totalInPlay
                                Text("$\(difference, specifier: "%.2f")")
                                    .font(.headline)
                                    .foregroundColor(difference == 0 ? .green : .red)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                
                // The table - will scroll to show the active text field
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        HStack(spacing: 0) {
                            // LEFT (Pinned) COLUMN
                            VStack(spacing: 0) {
                                Text("Player")
                                    .font(.headline)
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.vertical, 8)
                                
                                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, _ in
                                    PlayerNameInput(
                                        name: $viewModel.players[index].name, 
                                        viewModel: viewModel,
                                        onFocus: { 
                                            editingPlayerIndex = index
                                            withAnimation {
                                                scrollProxy.scrollTo("player-\(index)", anchor: .top)
                                            }
                                        }
                                    )
                                    .frame(width: 100, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .id("player-\(index)")
                                }
                            }
                            
                            // RIGHT columns
                            ScrollView(.horizontal, showsIndicators: true) {
                                VStack(spacing: 0) {
                                    // Headers
                                    HStack(spacing: 0) {
                                        Text("Buy-ins")
                                            .font(.headline)
                                            .frame(width: 200, alignment: .leading)
                                        Text("Paid?")
                                            .font(.headline)
                                            .frame(width: 60, alignment: .center)
                                        Text("Chips")
                                            .font(.headline)
                                            .frame(width: 80, alignment: .leading)
                                        Text("P/L")
                                            .font(.headline)
                                            .frame(width: 80, alignment: .leading)
                                        Text("")
                                            .font(.headline)
                                            .frame(width: 40, alignment: .center)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, p in
                                        HStack(spacing: 0) {
                                            BuyInsDisplay(
                                                buyIns: viewModel.players[index].buyIns,
                                                playerIndex: index,
                                                onAddBuyIn: {
                                                    selectedPlayerIndex = index
                                                    // Auto-detect type
                                                    buyInType = viewModel.players[index].buyIns.isEmpty ? .initial : .rebuy
                                                    buyInAmount = viewModel.buyInText
                                                    showingAddBuyInSheet = true
                                                },
                                                onDeleteBuyIn: { buyInId in
                                                    viewModel.removeBuyIn(for: index, buyInId: buyInId)
                                                }
                                            )
                                            
                                            Checkbox(isChecked: $viewModel.players[index].venmoStatus)
                                                .frame(width: 60)
                                            
                                            AmountInput(amount: $viewModel.players[index].chipCount)
                                            
                                            let profitLoss = viewModel.players[index].chipCount
                                                - viewModel.players[index].totalInvested
                                            Text(profitLoss.formatted(.currency(code: "USD")))
                                                .frame(width: 80, alignment: .leading)
                                                .foregroundColor(profitLoss >= 0 ? .green : .red)
                                            
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                // Bottom buttons
                if !keyboardVisible {
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
                                viewModel.showingEndGameAlert = true
                            }) {
                                Text("End & Save")
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                Text("Reset Game")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
            }
            .navigationBarItems(trailing:
                NavigationLink(
                    destination: LogsView(viewModel: viewModel),
                    isActive: $viewModel.shouldShowLogs
                ) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardVisible = false
            }
            .onReceive(timer) { _ in
                if viewModel.isGameActive {
                    viewModel.currentTime = Date()
                }
            }
            .alert("Are you sure?", isPresented: $viewModel.showingEndGameAlert) {
                Button("Cancel", role: .cancel) { }
                Button("End & Save", role: .destructive) {
                    viewModel.endAndSaveGame()
                }
            } message: {
                Text("Game will reset and save to Logs")
            }
            .alert("Are you sure?", isPresented: $showingResetAlert) {
                Button("No", role: .cancel) { }
                Button("Yes", role: .destructive) {
                    viewModel.resetGame()
                }
            } message: {
                Text("All values will be reset to zero.")
            }
            .sheet(isPresented: $showingAddBuyInSheet) {
                AddBuyInView(
                    amount: $buyInAmount,
                    buyInType: $buyInType,
                    onSave: {
                        if let index = selectedPlayerIndex,
                           let amount = Double(buyInAmount), amount > 0 {
                            viewModel.addBuyIn(for: index, amount: amount)
                            buyInAmount = ""
                        }
                    }
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

