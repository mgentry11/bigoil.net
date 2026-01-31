
import WidgetKit
import SwiftUI

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Statistics")
        .description("Overview of your training stats.")
        .supportedFamilies([.systemMedium])
    }
}

struct StatsWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 20) {
            // Main Stat: Weekly Workouts
            VStack(alignment: .leading, spacing: 4) {
                Text("THIS WEEK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.summary.weeklyWorkouts)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: min(geo.size.width * (Double(entry.summary.weeklyWorkouts) / 4.0), geo.size.width), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.gray)
            
            // Secondary Stats
            VStack(alignment: .leading, spacing: 12) {
                StatCompactRow(title: "Total Volume", value: formatVolume(entry.summary.totalVolume), icon: "dumbbell.fill", color: .blue)
                StatCompactRow(title: "Total Workouts", value: "\(entry.summary.totalWorkouts)", icon: "trophy.fill", color: .yellow)
                StatCompactRow(title: "Current Streak", value: "\(entry.summary.streak) days", icon: "flame.fill", color: .orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(white: 0.1)
        }
    }
    
    func formatVolume(_ volume: Double) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM", volume / 1000000)
        } else if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

struct StatCompactRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
    }
}
