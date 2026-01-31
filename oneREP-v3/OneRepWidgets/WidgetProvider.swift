
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), summary: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), summary: AppGroup.widgetSummary ?? .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch latest data from App Group
        let summary = AppGroup.widgetSummary ?? .placeholder
        
        // Create entry
        let entry = SimpleEntry(date: Date(), summary: summary)
        
        // Refresh policy: Update when app saves new data (via AppGroup.widgetSummary setter)
        // Also auto-refresh every hour to keep "Last workout" text relative
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSummary
}

extension WidgetSummary {
    static var placeholder: WidgetSummary {
        WidgetSummary(
            streak: 3,
            totalWorkouts: 42,
            weeklyWorkouts: 2,
            lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            lastWorkoutType: "A",
            totalVolume: 15000,
            primaryProfile: 1
        )
    }
}
