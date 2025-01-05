import Foundation

struct GameLog: Identifiable, Codable {
    let id: UUID
    let endDate: Date
    let duration: Int?
    let location: String?
    let players: [PlayerResult]
    let totalBuyIn: Double
    let totalChipCount: Double
    
    init(
        id: UUID = UUID(),
        endDate: Date = Date(),
        duration: Int? = nil,
        location: String? = nil,
        players: [PlayerResult],
        totalBuyIn: Double,
        totalChipCount: Double
    ) {
        self.id = id
        self.endDate = endDate
        self.duration = duration
        self.location = location
        self.players = players
        self.totalBuyIn = totalBuyIn
        self.totalChipCount = totalChipCount
    }
}

struct PlayerResult: Identifiable, Codable {
    let id: UUID
    var name: String  // Changed to var to allow editing
    let buyIn: Double
    let finalChipCount: Double
    let venmoStatus: Bool
    
    var profitLoss: Double {
        return finalChipCount - buyIn
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        buyIn: Double,
        finalChipCount: Double,
        venmoStatus: Bool
    ) {
        self.id = id
        self.name = name
        self.buyIn = buyIn
        self.finalChipCount = finalChipCount
        self.venmoStatus = venmoStatus
    }
}

extension GameLog {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
    
    var totalProfitLoss: Double {
        return players.reduce(0) { $0 + $1.profitLoss }
    }
    
    var biggestWinner: PlayerResult? {
        return players.max(by: { $0.profitLoss < $1.profitLoss })
    }
    
    var biggestLoser: PlayerResult? {
        return players.min(by: { $0.profitLoss < $1.profitLoss })
    }
    
    var isBalanced: Bool {
        return abs(totalChipCount - totalBuyIn) < 0.01
    }
}
