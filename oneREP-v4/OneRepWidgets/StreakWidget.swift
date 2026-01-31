//
//  StreakWidget.swift
//  OneRepStrength v4
//
//  Redesigned streak widget with v4 dark theme
//

import WidgetKit
import SwiftUI

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Track your workout streak.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetEntryView: View {
    var entry: Provider.Entry

    // V4 Theme Colors
    private let backgroundColor = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2) // Orange accent

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 8) {
                // Flame icon with gradient
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 6)

                // Streak number
                Text("\(entry.summary.streak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText(value: Double(entry.summary.streak)))

                // Label
                Text("DAY STREAK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
            }
        }
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}
