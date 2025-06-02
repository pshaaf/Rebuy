import SwiftUI

struct LogsView: View {
    @ObservedObject var viewModel: PokerGameViewModel
    @State private var selectedPlayer: PlayerResult?
    @State private var isShowingPlayerStats = false
    
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
                    
                    // Player results - sorted by P/L descending
                    ForEach(log.players.sorted { player1, player2 in
                        let profitLoss1 = player1.finalChipCount - player1.buyIn
                        let profitLoss2 = player2.finalChipCount - player2.buyIn
                        return profitLoss1 > profitLoss2
                    }) { player in
                        Button(action: {
                            self.selectedPlayer = player
                            self.isShowingPlayerStats = true
                        }) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(player.name)
                                        .foregroundColor(.blue)
                                        .underline()
                                    
                                    Spacer()
                                    let profitLoss = player.finalChipCount - player.buyIn
                                    Text(profitLoss.formatted(.currency(code: "USD")))
                                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                                }
                                .font(.subheadline)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
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
        .background(
            NavigationLink(
                destination: selectedPlayer.map { PlayerStatsView(playerStats: viewModel.getPlayerStats(for: $0)) },
                isActive: $isShowingPlayerStats,
                label: { EmptyView() }
            )
            .hidden()
        )
        .onDisappear {
            // Reset selection state when view disappears
            selectedPlayer = nil
            isShowingPlayerStats = false
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
