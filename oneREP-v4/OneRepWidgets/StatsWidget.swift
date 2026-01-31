//
//  StatsWidget.swift
//  OneRepStrength v4
//
//  Redesigned stats widget with v4 dark theme
//

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

    // V4 Theme Colors
    private let backgroundColor = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    private let cardBackground = Color(red: 0.102, green: 0.102, blue: 0.122) // #1A1A1F
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        HStack(spacing: 16) {
            // Main Stat: Weekly Workouts
            VStack(alignment: .leading, spacing: 6) {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(0.5)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.summary.weeklyWorkouts)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("workouts")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentOrange.opacity(0.8), accentOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(geo.size.width * (Double(entry.summary.weeklyWorkouts) / 4.0), geo.size.width), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)

            // Secondary Stats
            VStack(alignment: .leading, spacing: 10) {
                StatCompactRowV4(
                    title: "Total Volume",
                    value: formatVolume(entry.summary.totalVolume),
                    icon: "dumbbell.fill",
                    color: .blue
                )
                StatCompactRowV4(
                    title: "Total Workouts",
                    value: "\(entry.summary.totalWorkouts)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                StatCompactRowV4(
                    title: "Current Streak",
                    value: "\(entry.summary.streak) days",
                    icon: "flame.fill",
                    color: accentOrange
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            backgroundColor
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

struct StatCompactRowV4: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
    }
}
