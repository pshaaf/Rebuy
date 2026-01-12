import Foundation

// MARK: - Active Game State (for persistence)
struct ActiveGame: Codable {
    let players: [Player]
    let buyInText: String
    let gameStartTime: Date?
    let isGameActive: Bool
}

// MARK: - Manual Game Entry
struct ManualGameEntry: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let profitLoss: Double
    let date: Date
    
    init(id: UUID = UUID(), playerName: String, profitLoss: Double, date: Date) {
        self.id = id
        self.playerName = playerName
        self.profitLoss = profitLoss
        self.date = date
    }
}

// MARK: - Imported Game Entry
struct ImportedGameEntry: Identifiable, Codable {
    let id: UUID
    let playerName: String
    let profitLoss: Double
    let date: Date
    let sourceFile: String?
    let importDate: Date
    
    init(id: UUID = UUID(), playerName: String, profitLoss: Double, date: Date,
         sourceFile: String? = nil, importDate: Date = Date()) {
        self.id = id
        self.playerName = playerName
        self.profitLoss = profitLoss
        self.date = date
        self.sourceFile = sourceFile
        self.importDate = importDate
    }
}

// MARK: - Export Models
struct PlayerExport: Codable {
    let playerName: String
    let exportDate: Date
    let appVersion: String
    let games: [GameExport]
}

struct GameExport: Codable {
    let date: Date
    let profitLoss: Double
    let totalBuyIn: Double
    let duration: Int?
    let isManual: Bool
    let isImported: Bool
    let buyIns: [BuyInExport]
}

struct BuyInExport: Codable {
    let amount: Double
    let type: String
}

// MARK: - BuyIn Models
struct BuyIn: Identifiable, Codable, Equatable {
    let id: UUID
    let amount: Double
    let timestamp: Date
    let type: BuyInType
    
    init(id: UUID = UUID(), amount: Double, timestamp: Date = Date(), type: BuyInType) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.type = type
    }
}

enum BuyInType: String, Codable {
    case initial = "Initial"
    case rebuy = "Rebuy"
    case addOn = "Add-on"
    
    var color: String {
        switch self {
        case .initial: return "blue"
        case .rebuy: return "orange"
        case .addOn: return "purple"
        }
    }
}

// MARK: - GameLog
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
    var name: String
    let buyIns: [BuyIn]
    let finalChipCount: Double
    let venmoStatus: Bool
    
    var totalBuyIn: Double {
        return buyIns.reduce(0) { $0 + $1.amount }
    }
    
    var rebuyCount: Int {
        return buyIns.filter { $0.type != .initial }.count
    }
    
    var profitLoss: Double {
        return finalChipCount - totalBuyIn
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        buyIns: [BuyIn],
        finalChipCount: Double,
        venmoStatus: Bool
    ) {
        self.id = id
        self.name = name
        self.buyIns = buyIns
        self.finalChipCount = finalChipCount
        self.venmoStatus = venmoStatus
    }
    
    // MARK: - Migration Support for Backward Compatibility
    enum CodingKeys: String, CodingKey {
        case id, name, buyIns, buyIn, finalChipCount, venmoStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        finalChipCount = try container.decode(Double.self, forKey: .finalChipCount)
        venmoStatus = try container.decode(Bool.self, forKey: .venmoStatus)
        
        // Try new format first (array of BuyIns)
        if let buyInsArray = try? container.decode([BuyIn].self, forKey: .buyIns) {
            buyIns = buyInsArray
        } else if let oldBuyIn = try? container.decode(Double.self, forKey: .buyIn) {
            // Fallback to old format (single buyIn amount) - migrate to new format
            buyIns = [BuyIn(amount: oldBuyIn, timestamp: Date(), type: .initial)]
        } else {
            // Default to empty array if neither exists
            buyIns = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(buyIns, forKey: .buyIns)
        try container.encode(finalChipCount, forKey: .finalChipCount)
        try container.encode(venmoStatus, forKey: .venmoStatus)
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
