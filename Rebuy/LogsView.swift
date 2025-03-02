import SwiftUI

struct LogsView: View {
    @ObservedObject var viewModel: PokerGameViewModel
    
    // Computed property to sort logs by date
    private var sortedLogs: [GameLog] {
        viewModel.gameLogs.sorted { $0.endDate > $1.endDate }
    }
    
    var body: some View {
        List {
            ForEach(sortedLogs) { log in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(log.formattedDate)
                            .font(.headline)
                        Spacer()
                        Text("Total: \(log.totalBuyIn.formatted(.currency(code: "USD")))")
                            .foregroundColor(.gray)
                    }
                    
                    // Player results
                    ForEach(log.players) { player in
                        NavigationLink(destination: PlayerStatsView(playerStats: viewModel.getPlayerStats(for: player))) {
                            HStack {
                                Text(player.name)
                                
                                Spacer()
                                let profitLoss = player.finalChipCount - player.buyIn
                                Text(profitLoss.formatted(.currency(code: "USD")))
                                    .foregroundColor(profitLoss >= 0 ? .green : .red)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    // Game balance indicator
                    HStack {
                        Image(systemName: log.isBalanced ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(log.isBalanced ? .green : .red)
                        Text(log.isBalanced ? "Game Balanced" : "Game Unbalanced")
                            .font(.caption)
                            .foregroundColor(log.isBalanced ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteLog)
        }
        .navigationTitle("Game History")
        .toolbar {
            EditButton()
        }
    }
    
    func deleteLog(at offsets: IndexSet) {
        // Convert the offsets from the sorted array to the original array
        let sortedIndices = offsets.map { sortedLogs[$0].id }
        viewModel.gameLogs.removeAll { log in
            sortedIndices.contains(log.id)
        }
        
        if let encoded = try? JSONEncoder().encode(viewModel.gameLogs) {
            UserDefaults.standard.set(encoded, forKey: "GameLogs")
        }
    }
}

struct LogsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LogsView(viewModel: PokerGameViewModel())
        }
    }
}
