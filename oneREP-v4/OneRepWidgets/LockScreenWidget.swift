//
//  LockScreenWidget.swift
//  OneRepStrength v4
//
//  Redesigned lock screen widget with v4 dark theme
//

import WidgetKit
import SwiftUI

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Stats")
        .description("Quick stats on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    // V4 Theme accent
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(entry.summary.streak)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
            }

        case .accessoryRectangular:
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAST WORKOUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    if let date = entry.summary.lastWorkoutDate {
                        Text(date, style: .relative)
                            .font(.system(size: 15, weight: .bold))
                        Text("ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("No workouts")
                            .font(.system(size: 15, weight: .bold))
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(entry.summary.streak)")
                        .font(.system(size: 14, weight: .bold))
                }
            }

        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                Text("Streak: \(entry.summary.streak) days")
            }

        default:
            Text("N/A")
        }
    }
}
