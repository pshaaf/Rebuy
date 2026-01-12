import SwiftUI

// MARK: - Date Range Filter
enum DateRangeFilter: String, CaseIterable {
    case all = "ALL"
    case ytd = "YTD"
    case oneYear = "1Y"
    case mtd = "MTD"
    
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all:
            return nil
        case .ytd:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .mtd:
            return calendar.date(from: DateComponents(
                year: calendar.component(.year, from: now),
                month: calendar.component(.month, from: now)
            ))
        }
    }
}

struct PlayerStats {
    let name: String
    let games: [GameLog]
    let playerResults: [PlayerResult]
    let manualEntries: [ManualGameEntry]
    let importedEntries: [ImportedGameEntry]
    
    var totalProfitLoss: Double {
        let regularPL = playerResults.reduce(0) { $0 + $1.profitLoss }
        let manualPL = manualEntries.reduce(0) { $0 + $1.profitLoss }
        let importedPL = importedEntries.reduce(0) { $0 + $1.profitLoss }
        return regularPL + manualPL + importedPL
    }
    
    var totalGames: Int {
        return games.count + manualEntries.count + importedEntries.count
    }
    
    var averageGameDuration: Int? {
        let durations = games.compactMap { $0.duration }
        guard !durations.isEmpty else { return nil }
        let total = durations.reduce(0, +)
        return total / durations.count
    }
    
    // Rebuy statistics
    var totalRebuys: Int {
        playerResults.reduce(0) { $0 + $1.rebuyCount }
    }
    
    var rebuyRate: Double {
        guard !playerResults.isEmpty else { return 0 }
        let gamesWithRebuys = playerResults.filter { $0.rebuyCount > 0 }.count
        return Double(gamesWithRebuys) / Double(playerResults.count) * 100
    }
    
    var averageBuyInsPerGame: Double {
        guard !playerResults.isEmpty else { return 0 }
        let totalBuyIns = playerResults.reduce(0) { $0 + $1.buyIns.count }
        return Double(totalBuyIns) / Double(playerResults.count)
    }
    
    var totalInvested: Double {
        playerResults.reduce(0) { $0 + $1.totalBuyIn }
    }
    
    var gameHistory: [(date: Date, profitLoss: Double, duration: Int?, isManual: Bool, isImported: Bool, entryId: UUID?)] {
        // Combine regular games, manual entries, and imported entries
        let regularGames = zip(games, playerResults)
            .map { (game, result) in
                (date: game.endDate, profitLoss: result.profitLoss, duration: game.duration, isManual: false, isImported: false, entryId: nil as UUID?)
            }
        
        let manualGames = manualEntries.map { entry in
            (date: entry.date, profitLoss: entry.profitLoss, duration: nil as Int?, isManual: true, isImported: false, entryId: entry.id as UUID?)
        }
        
        let importedGames = importedEntries.map { entry in
            (date: entry.date, profitLoss: entry.profitLoss, duration: nil as Int?, isManual: false, isImported: true, entryId: entry.id as UUID?)
        }
        
        // Combine and sort by date - most recent first (for the Game Details list)
        return (regularGames + manualGames + importedGames).sorted { $0.date > $1.date }
    }
    
    var chartData: [(date: Date, individualPL: Double, cumulativePL: Double)] {
        // Combine regular games, manual entries, and imported entries
        let regularData = zip(games, playerResults)
            .map { (game, result) in
                (date: game.endDate, profitLoss: result.profitLoss)
            }
        
        let manualData = manualEntries.map { entry in
            (date: entry.date, profitLoss: entry.profitLoss)
        }
        
        let importedData = importedEntries.map { entry in
            (date: entry.date, profitLoss: entry.profitLoss)
        }
        
        // Sort by date - chronological order (oldest to newest for the chart)
        let sortedData = (regularData + manualData + importedData).sorted { $0.date < $1.date }
        
        // Calculate running total P/L while keeping individual game P/L
        var runningTotal: Double = 0
        return sortedData.map { item in
            runningTotal += item.profitLoss
            return (date: item.date, individualPL: item.profitLoss, cumulativePL: runningTotal)
        }
    }
}

// Chart dataset structure for multi-player comparison
struct ChartDataset {
    let playerName: String
    let data: [(date: Date, individualPL: Double, cumulativePL: Double)]
    let color: Color
}

struct ProfitLossChart: View {
    let datasets: [ChartDataset] // Changed from single data to array of datasets
    @State private var selectedPointIndex: Int? = nil
    @State private var selectedDatasetIndex: Int? = nil // Track which dataset's point is selected
    
    // Backward compatibility: single dataset initializer
    init(data: [(date: Date, individualPL: Double, cumulativePL: Double)]) {
        self.datasets = [ChartDataset(playerName: "Player", data: data, color: .blue)]
    }
    
    // New initializer for multiple datasets
    init(datasets: [ChartDataset]) {
        self.datasets = datasets
    }
    
    // Get all unique dates across all datasets for X-axis alignment
    private var allDates: [Date] {
        let allDatesSet = Set(datasets.flatMap { $0.data.map { $0.date } })
        return Array(allDatesSet).sorted()
    }
    
    // Get aligned data for a dataset (fills in missing dates with last known value)
    private func getAlignedData(for dataset: ChartDataset, dates: [Date]) -> [(date: Date, individualPL: Double, cumulativePL: Double)] {
        var result: [(date: Date, individualPL: Double, cumulativePL: Double)] = []
        var lastKnownPL: Double = 0
        
        for date in dates {
            // Find the data point for this date, or use the most recent before this date
            if let exactMatch = dataset.data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                result.append(exactMatch)
                lastKnownPL = exactMatch.cumulativePL
            } else {
                // Find the most recent data point before this date
                let previousPoints = dataset.data.filter { $0.date < date }
                if let mostRecent = previousPoints.max(by: { $0.date < $1.date }) {
                    result.append((date: date, individualPL: 0, cumulativePL: mostRecent.cumulativePL))
                    lastKnownPL = mostRecent.cumulativePL
                } else {
                    // No previous data, use zero
                    result.append((date: date, individualPL: 0, cumulativePL: 0))
                    lastKnownPL = 0
                }
            }
        }
        return result
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    private var tooltipDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            let alignedDates = allDates
            
            if alignedDates.isEmpty || datasets.isEmpty {
                Text("No game data available")
                    .foregroundColor(.gray)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
            } else if alignedDates.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    // Calculate chart area dimensions with proper margins
                    // Add minimal extra space just for tooltip visibility
                    let baseWidth = geometry.size.width
                    let tooltipSpace: CGFloat = 60 // Just enough space to see tooltips
                    let totalWidth = baseWidth + tooltipSpace
                    
                    let chartMargin = EdgeInsets(top: 30, leading: 40, bottom: 40, trailing: 20)
                    let chartWidth = baseWidth - chartMargin.leading - chartMargin.trailing
                    let chartHeight = geometry.size.height - chartMargin.top - chartMargin.bottom
                    
                    // Get aligned data for all datasets
                    let alignedDatasets = datasets.map { dataset in
                        (dataset: dataset, alignedData: getAlignedData(for: dataset, dates: alignedDates))
                    }
                    
                    // Find min and max across ALL datasets for scaling
                    let allCumulativeValues = alignedDatasets.flatMap { $0.alignedData.map { $0.cumulativePL } }
                    let maxProfit = allCumulativeValues.max() ?? 0
                    let minProfit = min(allCumulativeValues.min() ?? 0, 0) // Ensure we include zero
                    let range = max(maxProfit - minProfit, 1.0)
                    
                    // Calculate zero Y position
                    let zeroY = chartMargin.top + chartHeight * (maxProfit / range)
                    
                    ZStack(alignment: .topLeading) {
                        // Zero line (only reference line we keep)
                        if minProfit < 0 && maxProfit > 0 {
                            Path { path in
                                path.move(to: CGPoint(x: chartMargin.leading, y: zeroY))
                                path.addLine(to: CGPoint(x: baseWidth - chartMargin.trailing, y: zeroY))
                            }
                            .stroke(Color.gray.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            
                            // Zero label
                            Text("$0")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .position(x: chartMargin.leading - 15, y: zeroY)
                        }
                        
                        // X-axis (bottom line only)
                        Path { path in
                            path.move(to: CGPoint(x: chartMargin.leading, y: chartMargin.top + chartHeight))
                            path.addLine(to: CGPoint(x: baseWidth - chartMargin.trailing, y: chartMargin.top + chartHeight))
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        
                        // Date labels (use aligned dates)
                        ForEach(0..<alignedDates.count, id: \.self) { i in
                            let xPos = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(max(alignedDates.count - 1, 1))))
                            
                            // Date label
                            Text(dateFormatter.string(from: alignedDates[i]))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .position(x: xPos, y: chartMargin.top + chartHeight + 20)
                        }
                        
                        // Draw lines for each dataset
                        ForEach(Array(alignedDatasets.enumerated()), id: \.offset) { datasetIndex, alignedDataset in
                            let dataset = alignedDataset.dataset
                            let alignedData = alignedDataset.alignedData
                            
                            // Curved chart line (uses cumulative P/L)
                            Path { path in
                                guard alignedData.count > 1 else { return }
                                
                                // Convert data points to chart coordinates using cumulative P/L
                                let points = alignedData.enumerated().map { (index, item) in
                                    let x = chartMargin.leading + (CGFloat(index) * (chartWidth / CGFloat(max(alignedDates.count - 1, 1))))
                                    let y = chartMargin.top + chartHeight * (1 - (item.cumulativePL - minProfit) / range)
                                    return CGPoint(x: x, y: y)
                                }
                                
                                // Start the path
                                path.move(to: points[0])
                                
                                // Create smooth curves between points
                                for i in 1..<points.count {
                                    let previousPoint = points[i-1]
                                    let currentPoint = points[i]
                                    
                                    // Calculate control points for smooth curve
                                    let controlPoint1 = CGPoint(
                                        x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.4,
                                        y: previousPoint.y
                                    )
                                    let controlPoint2 = CGPoint(
                                        x: currentPoint.x - (currentPoint.x - previousPoint.x) * 0.4,
                                        y: currentPoint.y
                                    )
                                    
                                    path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
                                }
                            }
                            .stroke(dataset.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            
                            // Data points (only show for primary player - first dataset, or when selected)
                            if datasetIndex == 0 || (selectedDatasetIndex == datasetIndex && selectedPointIndex != nil) {
                                ForEach(0..<alignedData.count, id: \.self) { i in
                                    let x = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(max(alignedDates.count - 1, 1))))
                                    let y = chartMargin.top + chartHeight * (1 - (alignedData[i].cumulativePL - minProfit) / range)
                                    
                                    // Only show points for actual games (not interpolated)
                                    if alignedData[i].individualPL != 0 || i == 0 {
                                        Button(action: {
                                            if selectedPointIndex == i && selectedDatasetIndex == datasetIndex {
                                                selectedPointIndex = nil
                                                selectedDatasetIndex = nil
                                            } else {
                                                selectedPointIndex = i
                                                selectedDatasetIndex = datasetIndex
                                            }
                                        }) {
                                            Circle()
                                                .fill(alignedData[i].individualPL >= 0 ? Color.green : Color.red)
                                                .frame(width: (selectedPointIndex == i && selectedDatasetIndex == datasetIndex) ? 12 : 8,
                                                       height: (selectedPointIndex == i && selectedDatasetIndex == datasetIndex) ? 12 : 8)
                                                .scaleEffect((selectedPointIndex == i && selectedDatasetIndex == datasetIndex) ? 1.2 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: selectedPointIndex)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .position(x: x, y: y)
                                    }
                                }
                            }
                        }
                        
                        // Tooltip for selected point
                        if let selectedIndex = selectedPointIndex, let datasetIndex = selectedDatasetIndex,
                           datasetIndex < alignedDatasets.count {
                            let alignedData = alignedDatasets[datasetIndex].alignedData
                            let dataset = alignedDatasets[datasetIndex].dataset
                            
                            if selectedIndex < alignedData.count {
                                let selectedData = alignedData[selectedIndex]
                                let x = chartMargin.leading + (CGFloat(selectedIndex) * (chartWidth / CGFloat(max(alignedDates.count - 1, 1))))
                                let y = chartMargin.top + chartHeight * (1 - (selectedData.cumulativePL - minProfit) / range)
                                
                                // Position tooltip above or below point based on available space
                                let tooltipY = y < geometry.size.height / 2 ? y + 50 : y - 50
                                
                                VStack(spacing: 4) {
                                    Text(dataset.playerName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(tooltipDateFormatter.string(from: selectedData.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    // Individual game P/L
                                    if selectedData.individualPL != 0 {
                                        HStack(spacing: 4) {
                                            Text("Game:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(selectedData.individualPL.formatted(.currency(code: "USD")))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedData.individualPL >= 0 ? .green : .red)
                                        }
                                    }
                                    
                                    // Overall P/L at this point
                                    HStack(spacing: 4) {
                                        Text("Overall:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(selectedData.cumulativePL.formatted(.currency(code: "USD")))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(selectedData.cumulativePL >= 0 ? .green : .red)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .position(x: x, y: tooltipY)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.2), value: selectedPointIndex)
                            }
                        }
                    }
                    .frame(width: totalWidth, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Tap outside to deselect
                        selectedPointIndex = nil
                        selectedDatasetIndex = nil
                    }
                }
                .overlay(alignment: .top) {
                    // Legend for multiple datasets
                    if datasets.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(datasets.enumerated()), id: \.offset) { index, dataset in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(dataset.color)
                                            .frame(width: 12, height: 12)
                                        Text(dataset.playerName)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .frame(height: 30)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                }
            } else if alignedDates.count == 1 {
                // For a single data point
                VStack(spacing: 10) {
                    Text("Only one game played")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    ForEach(Array(datasets.enumerated()), id: \.offset) { index, dataset in
                        if let firstData = dataset.data.first {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(dataset.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(dataset.playerName)
                                    .font(.caption)
                                
                                Text(dateFormatter.string(from: firstData.date))
                                    .font(.caption)
                                
                                Text(firstData.cumulativePL.formatted(.currency(code: "USD")))
                                    .font(.caption)
                                    .foregroundColor(firstData.cumulativePL >= 0 ? .green : .red)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
            }
        }
    }
}

struct PlayerStatsView: View {
    let player: PlayerResult
    @ObservedObject var viewModel: PokerGameViewModel
    @State private var showingAddManualEntry = false
    @State private var entryToDelete: UUID? = nil
    @State private var isDeletedEntryImported = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedDateRange: DateRangeFilter = .all
    
    // Export file URL for sharing
    private var exportFileURL: URL? {
        viewModel.createExportFileURL(for: player.name)
    }
    
    // Computed property that dynamically fetches stats from viewModel
    // This ensures the view updates when manualGameEntries changes
    var playerStats: PlayerStats {
        viewModel.getPlayerStats(for: player)
    }
    
    // Chart data for the player
    private var chartData: [(date: Date, individualPL: Double, cumulativePL: Double)] {
        playerStats.chartData
    }
    
    // Filtered game history based on selected date range
    private var filteredGameHistory: [(date: Date, profitLoss: Double, duration: Int?, isManual: Bool, isImported: Bool, entryId: UUID?)] {
        guard let startDate = selectedDateRange.startDate else {
            return playerStats.gameHistory
        }
        return playerStats.gameHistory.filter { $0.date >= startDate }
    }
    
    // Filtered chart data based on selected date range (recalculates cumulative totals)
    private var filteredChartData: [(date: Date, individualPL: Double, cumulativePL: Double)] {
        guard let startDate = selectedDateRange.startDate else {
            return playerStats.chartData
        }
        
        // Filter to only include data points within the date range
        let filteredData = playerStats.chartData.filter { $0.date >= startDate }
        
        // Recalculate cumulative totals starting from zero for the filtered range
        var runningTotal: Double = 0
        return filteredData.map { item in
            runningTotal += item.individualPL
            return (date: item.date, individualPL: item.individualPL, cumulativePL: runningTotal)
        }
    }
    
    // Helper function to format duration
    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else { return "N/A" }
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Player name
                Text(playerStats.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Overall P/L
                VStack(spacing: 8) {
                    Text("Overall Profit/Loss")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text(playerStats.totalProfitLoss.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundColor(playerStats.totalProfitLoss >= 0 ? .green : .red)
                }
                .padding(.horizontal)
                
                // Statistics grid
                VStack(spacing: 12) {
                    // Total invested
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Total Invested")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(playerStats.totalInvested.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("Games Played")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(playerStats.totalGames)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rebuy statistics
                    if playerStats.totalRebuys > 0 {
                        VStack(spacing: 8) {
                            Text("Rebuy Statistics")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text("Total Rebuys")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(playerStats.totalRebuys)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack(spacing: 4) {
                                    Text("Rebuy Rate")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(playerStats.rebuyRate, specifier: "%.0f")%")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack(spacing: 4) {
                                    Text("Avg Buy-ins")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(playerStats.averageBuyInsPerGame, specifier: "%.1f")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Average game duration
                    if let avgDuration = playerStats.averageGameDuration {
                        VStack(spacing: 8) {
                            Text("Average Game Duration")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text(formatDuration(avgDuration))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // Line graph
                if !playerStats.gameHistory.isEmpty {
                    HStack {
                        Text("Performance History")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 16) {
                            ForEach(DateRangeFilter.allCases, id: \.self) { filter in
                                Button(filter.rawValue) {
                                    selectedDateRange = filter
                                }
                                .font(.subheadline)
                                .fontWeight(selectedDateRange == filter ? .bold : .regular)
                                .foregroundColor(selectedDateRange == filter ? .blue : .gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ProfitLossChart(data: filteredChartData)
                        .frame(height: 350)
                        .padding()
                } else {
                    Text("No game history available")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Game Details Header
                Text("Game Details")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Game details list - embedded non-scrollable List
                if !filteredGameHistory.isEmpty {
                    List {
                        ForEach(filteredGameHistory.indices, id: \.self) { index in
                            let historyItem = filteredGameHistory[index]
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if historyItem.isImported {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                    } else if historyItem.isManual {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    Text(historyItem.date.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    Text(historyItem.profitLoss.formatted(.currency(code: "USD")))
                                        .foregroundColor(historyItem.profitLoss >= 0 ? .green : .red)
                                }
                                
                                if let duration = historyItem.duration {
                                    Text("Duration: \(formatDuration(duration))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if historyItem.isImported {
                                    Text("Imported Entry")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                } else if historyItem.isManual {
                                    Text("Manual Entry")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if historyItem.isImported, let entryId = historyItem.entryId {
                                    Button(role: .destructive) {
                                        entryToDelete = entryId
                                        isDeletedEntryImported = true
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } else if historyItem.isManual, let entryId = historyItem.entryId {
                                    Button(role: .destructive) {
                                        entryToDelete = entryId
                                        isDeletedEntryImported = false
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: CGFloat(filteredGameHistory.count) * 60)
                    .scrollDisabled(true)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Player Stats")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Export button
                    if let url = exportFileURL {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Add manual entry button
                    Button(action: {
                        showingAddManualEntry = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddManualEntry) {
            AddManualGameView(playerName: playerStats.name) { profitLoss, date in
                viewModel.addManualEntry(playerName: playerStats.name, profitLoss: profitLoss, date: date)
            }
        }
        .confirmationDialog(
            isDeletedEntryImported ? "Delete Imported Entry?" : "Delete Manual Entry?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let id = entryToDelete {
                    if isDeletedEntryImported {
                        viewModel.deleteImportedEntry(id: id)
                    } else {
                        viewModel.deleteManualEntry(id: id)
                    }
                    entryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text(isDeletedEntryImported
                 ? "Are you sure you want to delete this imported entry? This action cannot be undone."
                 : "Are you sure you want to delete this manual entry? This action cannot be undone.")
        }
    }
}

struct PlayerStatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlayerStatsView(
                player: PlayerResult(
                    name: "Sample Player",
                    buyIns: [],
                    finalChipCount: 0,
                    venmoStatus: false
                ),
                viewModel: PokerGameViewModel()
            )
        }
    }
} 
