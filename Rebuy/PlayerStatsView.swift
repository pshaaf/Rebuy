import SwiftUI

struct PlayerStats {
    let name: String
    let games: [GameLog]
    let playerResults: [PlayerResult]
    
    var totalProfitLoss: Double {
        playerResults.reduce(0) { $0 + $1.profitLoss }
    }
    
    var gameHistory: [(date: Date, profitLoss: Double)] {
        // Sort by date
        return zip(games, playerResults)
            .map { (game, result) in
                (date: game.endDate, profitLoss: result.profitLoss)
            }
            .sorted { $0.date < $1.date }
    }
}

struct ProfitLossChart: View {
    let data: [(date: Date, profitLoss: Double)]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                // Calculate chart area dimensions with proper margins
                let chartMargin = EdgeInsets(top: 30, leading: 60, bottom: 40, trailing: 20)
                let chartWidth = geometry.size.width - chartMargin.leading - chartMargin.trailing
                let chartHeight = geometry.size.height - chartMargin.top - chartMargin.bottom
                
                // Find min and max for scaling
                let maxProfit = data.map { $0.profitLoss }.max() ?? 0
                let minProfit = min(data.map { $0.profitLoss }.min() ?? 0, 0) // Ensure we include zero
                let range = max(maxProfit - minProfit, 1.0)
                
                // Calculate zero Y position
                let zeroY = chartMargin.top + chartHeight * (maxProfit / range)
                
                ZStack(alignment: .topLeading) {
                    // Y-axis label
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.gray)
                        Text("Profit/Loss")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .rotationEffect(Angle(degrees: -90))
                    .position(x: 15, y: geometry.size.height / 2)
                    
                    // Y-axis with tick marks
                    Group {
                        // Y-axis line
                        Path { path in
                            path.move(to: CGPoint(x: chartMargin.leading, y: chartMargin.top))
                            path.addLine(to: CGPoint(x: chartMargin.leading, y: chartMargin.top + chartHeight))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        
                        // Zero line
                        if minProfit < 0 && maxProfit > 0 {
                            Path { path in
                                path.move(to: CGPoint(x: chartMargin.leading, y: zeroY))
                                path.addLine(to: CGPoint(x: geometry.size.width - chartMargin.trailing, y: zeroY))
                            }
                            .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            
                            // Zero label
                            Text("$0")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .position(x: chartMargin.leading - 20, y: zeroY)
                        }
                        
                        // Max value tick and label
                        Text(maxProfit.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .position(x: chartMargin.leading - 25, y: chartMargin.top)
                        
                        // Min value tick and label
                        Text(minProfit.formatted(.currency(code: "USD")))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .position(x: chartMargin.leading - 25, y: chartMargin.top + chartHeight)
                    }
                    
                    // X-axis
                    Group {
                        // X-axis line
                        Path { path in
                            path.move(to: CGPoint(x: chartMargin.leading, y: chartMargin.top + chartHeight))
                            path.addLine(to: CGPoint(x: geometry.size.width - chartMargin.trailing, y: chartMargin.top + chartHeight))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        
                        // Date labels
                        ForEach(0..<data.count, id: \.self) { i in
                            let xPos = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(data.count - 1)))
                            
                            // Tick mark
                            Path { path in
                                path.move(to: CGPoint(x: xPos, y: chartMargin.top + chartHeight))
                                path.addLine(to: CGPoint(x: xPos, y: chartMargin.top + chartHeight + 5))
                            }
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            
                            // Date label
                            Text(dateFormatter.string(from: data[i].date))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .position(x: xPos, y: chartMargin.top + chartHeight + 20)
                        }
                    }
                    
                    // Chart line
                    Path { path in
                        // Start the path
                        let startX = chartMargin.leading
                        let startY = chartMargin.top + chartHeight * (1 - (data[0].profitLoss - minProfit) / range)
                        
                        path.move(to: CGPoint(x: startX, y: startY))
                        
                        // Draw the line
                        for i in 1..<data.count {
                            let x = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(data.count - 1)))
                            let y = chartMargin.top + chartHeight * (1 - (data[i].profitLoss - minProfit) / range)
                            
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // Data points
                    ForEach(0..<data.count, id: \.self) { i in
                        let x = chartMargin.leading + (CGFloat(i) * (chartWidth / CGFloat(data.count - 1)))
                        let y = chartMargin.top + chartHeight * (1 - (data[i].profitLoss - minProfit) / range)
                        
                        Circle()
                            .fill(data[i].profitLoss >= 0 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
            VStack(alignment: .leading, spacing: 20) {
                // Player name
                Text(playerStats.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Overall P/L
                HStack {
                    Text("Overall Profit/Loss:")
                        .font(.headline)
                    Text(playerStats.totalProfitLoss.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundColor(playerStats.totalProfitLoss >= 0 ? .green : .red)
                }
                .padding(.horizontal)
                
                // Line graph
                if !playerStats.gameHistory.isEmpty {
                    Text("Performance History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ProfitLossChart(data: playerStats.gameHistory)
                        .frame(height: 200)
                        .padding()
                } else {
                    Text("No game history available")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // Game details
                Text("Game Details")
                    .font(.headline)
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
