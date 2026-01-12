import SwiftUI
import UniformTypeIdentifiers

struct LogsView: View {
    @ObservedObject var viewModel: PokerGameViewModel
    @State private var selectedPlayer: PlayerResult?
    @State private var isShowingPlayerStats = false
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var showingImportError = false
    
    // Computed property to sort logs by date
    private var sortedLogs: [GameLog] {
        viewModel.gameLogs.sorted { $0.endDate > $1.endDate }
    }
    
    // Helper function to format duration
    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else { return "" }
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return " • \(hours)h \(minutes)m"
        } else {
            return " • \(minutes)m"
        }
    }
    
    var body: some View {
        List {
            ForEach(sortedLogs) { log in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.formattedDate + formatDuration(log.duration))
                                .font(.headline)
                            
                            // Show rebuy count if any
                            let totalRebuys = log.players.reduce(0) { $0 + $1.rebuyCount }
                            if totalRebuys > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("\(totalRebuys) rebuy\(totalRebuys == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("Total: \(log.totalBuyIn.formatted(.currency(code: "USD")))")
                            .foregroundColor(.gray)
                    }
                    
                    // Player results - sorted by P/L descending
                    ForEach(log.players.sorted { player1, player2 in
                        return player1.profitLoss > player2.profitLoss
                    }) { player in
                        Button(action: {
                            self.selectedPlayer = player
                            self.isShowingPlayerStats = true
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(player.name)
                                        .foregroundColor(.blue)
                                        .underline()
                                    
                                    Spacer()
                                    Text(player.profitLoss.formatted(.currency(code: "USD")))
                                        .foregroundColor(player.profitLoss >= 0 ? .green : .red)
                                }
                                .font(.subheadline)
                                
                                // Show buy-in details if multiple buy-ins
                                if player.buyIns.count > 1 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                        Text("\(player.buyIns.count) buy-ins • Total: \(player.totalBuyIn.formatted(.currency(code: "USD")))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else if !player.buyIns.isEmpty {
                                    Text("Buy-in: \(player.totalBuyIn.formatted(.currency(code: "USD")))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingImporter = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .font(.subheadline)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        try viewModel.importPlayerHistory(from: url)
                    } catch {
                        importError = error.localizedDescription
                        showingImportError = true
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
                showingImportError = true
            }
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError ?? "Unknown error occurred")
        }
        .background(
            NavigationLink(
                destination: selectedPlayer.map { PlayerStatsView(player: $0, viewModel: viewModel) },
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
