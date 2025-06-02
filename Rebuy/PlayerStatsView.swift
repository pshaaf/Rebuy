import SwiftUI

struct PlayerStats {
    let name: String
    let games: [GameLog]
    let playerResults: [PlayerResult]
    
    var totalProfitLoss: Double {
        playerResults.reduce(0) { $0 + $1.profitLoss }
    }
    
    var gameHistory: [(date: Date, profitLoss: Double)] {
        // Sort by date - most recent first (for the Game Details list)
        return zip(games, playerResults)
            .map { (game, result) in
                (date: game.endDate, profitLoss: result.profitLoss)
            }
            .sorted { $0.date > $1.date }
    }
    
    var chartData: [(date: Date, profitLoss: Double)] {
        // Sort by date - chronological order (oldest to newest for the chart)
        return zip(games, playerResults)
            .map { (game, result) in
                (date: game.endDate, profitLoss: result.profitLoss)
            }
            .sorted { $0.date < $1.date }
    }
}

struct ProfitLossChart: View {
    let data: [(date: Date, profitLoss: Double)]
    @State private var selectedPointIndex: Int? = nil
    
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
            if data.count > 1 {
                // Calculate chart area dimensions with proper margins
                let chartMargin = EdgeInsets(top: 30, leading: 40, bottom: 40, trailing: 20)
                let chartWidth = geometry.size.width - chartMargin.leading - chartMargin.trailing
                let chartHeight = geometry.size.height - chartMargin.top - chartMargin.bottom
                
                // Find min and max for scaling
                let maxProfit = data.map { $0.profitLoss }.max() ?? 0
                let minProfit = min(data.map { $0.profitLoss }.min() ?? 0, 0) // Ensure we include zero
                let range = max(maxProfit - minProfit, 1.0)
                
                // Calculate zero Y position
                let zeroY = chartMargin.top + chartHeight * (maxProfit / range)
                
                ZStack(alignment: .topLeading) {
                    // Zero line (only reference line we keep)
                    if minProfit < 0 && maxProfit > 0 {
                        Path { path in
                            path.move(to: CGPoint(x: chartMargin.leading, y: zeroY))
                            path.addLine(to: CGPoint(x: geometry.size.width - chartMargin.trailing, y: zeroY))
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
                        path.addLine(to: CGPoint(x: geometry.size.width - chartMargin.trailing, y: chartMargin.top + chartHeight))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    
                    // Date labels
                    ForEach(0..<data.count, id: \.self) { i in
                        let xPos = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(data.count - 1)))
                        
                        // Date label
                        Text(dateFormatter.string(from: data[i].date))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .position(x: xPos, y: chartMargin.top + chartHeight + 20)
                    }
                    
                    // Curved chart line
                    Path { path in
                        guard data.count > 1 else { return }
                        
                        // Convert data points to chart coordinates
                        let points = data.enumerated().map { (index, item) in
                            let x = chartMargin.leading + (CGFloat(index) * (chartWidth / CGFloat(data.count - 1)))
                            let y = chartMargin.top + chartHeight * (1 - (item.profitLoss - minProfit) / range)
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
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(0..<data.count, id: \.self) { i in
                        let x = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(data.count - 1)))
                        let y = chartMargin.top + chartHeight * (1 - (data[i].profitLoss - minProfit) / range)
                        
                        Button(action: {
                            selectedPointIndex = selectedPointIndex == i ? nil : i
                        }) {
                            Circle()
                                .fill(data[i].profitLoss >= 0 ? Color.green : Color.red)
                                .frame(width: selectedPointIndex == i ? 12 : 8, 
                                       height: selectedPointIndex == i ? 12 : 8)
                                .scaleEffect(selectedPointIndex == i ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedPointIndex)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .position(x: x, y: y)
                    }
                    
                    // Tooltip for selected point
                    if let selectedIndex = selectedPointIndex {
                        let selectedData = data[selectedIndex]
                        let x = chartMargin.leading + (CGFloat(selectedIndex) * (chartWidth / CGFloat(data.count - 1)))
                        let y = chartMargin.top + chartHeight * (1 - (selectedData.profitLoss - minProfit) / range)
                        
                        // Position tooltip above or below point based on available space
                        let tooltipY = y < geometry.size.height / 2 ? y + 40 : y - 40
                        
                        VStack(spacing: 4) {
                            Text(tooltipDateFormatter.string(from: selectedData.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(selectedData.profitLoss.formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedData.profitLoss >= 0 ? .green : .red)
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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap outside to deselect
                    selectedPointIndex = nil
                }
            } else if data.count == 1 {
                // For a single data point
                VStack(spacing: 10) {
                    Text("Only one game played")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    HStack(spacing: 5) {
                        Text(dateFormatter.string(from: data[0].date))
                            .font(.caption)
                        
                        Circle()
                            .fill(data[0].profitLoss >= 0 ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(data[0].profitLoss.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .foregroundColor(data[0].profitLoss >= 0 ? .green : .red)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
            } else {
                Text("No game data available")
                    .foregroundColor(.gray)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
            }
        }
    }
}

struct PlayerStatsView: View {
    let playerStats: PlayerStats
    
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
                
                // Line graph
                if !playerStats.gameHistory.isEmpty {
                    Text("Performance History")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ProfitLossChart(data: playerStats.chartData)
                        .frame(height: 200)
                        .padding()
                } else {
                    Text("No game history available")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Game details
                Text("Game Details")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ForEach(playerStats.gameHistory.indices, id: \.self) { index in
                    let historyItem = playerStats.gameHistory[index]
                    HStack {
                        Text(historyItem.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(historyItem.profitLoss.formatted(.currency(code: "USD")))
                            .foregroundColor(historyItem.profitLoss >= 0 ? .green : .red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Player Stats")
    }
}

struct PlayerStatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlayerStatsView(playerStats: PlayerStats(
                name: "Sample Player",
                games: [],
                playerResults: []
            ))
        }
    }
} 
