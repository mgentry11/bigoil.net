
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
    
    var body: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()
            
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("\(entry.summary.streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText(value: Double(entry.summary.streak)))
                
                Text("DAY STREAK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .containerBackground(for: .widget) {
            Color(white: 0.1)
        }
    }
}
