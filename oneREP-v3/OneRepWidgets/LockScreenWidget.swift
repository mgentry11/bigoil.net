
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
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("\(entry.summary.streak)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Text("LAST WORKOUT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    if let date = entry.summary.lastWorkoutDate {
                        Text(date, style: .relative)
                            .font(.headline)
                        Text("ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No workouts")
                            .font(.headline)
                    }
                }
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
            }
        case .accessoryInline:
            Text("Streak: \(entry.summary.streak) days")
        default:
            Text("N/A")
        }
    }
}
