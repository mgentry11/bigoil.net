//
//  StreakWidget.swift
//  OneRepStrengthWidget
//
//  Lock Screen and Home Screen widget displaying current workout streak
//  Uses modern "Liquid Glass" aesthetic with vibrant gradients
//

import WidgetKit
import SwiftUI

// MARK: - App Group Configuration
/// App Group identifier for sharing data between main app and widget
let appGroupIdentifier = "group.com.onerepstrength.shared"

// MARK: - Shared Data Provider
struct StreakDataProvider {
    private static let storageKey = "workoutLogs"
    
    /// Get current workout streak for a profile
    static func getCurrentStreak(for profile: Int) -> Int {
        let logs = loadLogs().filter { $0.profile == profile }
        guard !logs.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check up to 30 days back
        for _ in 0..<30 {
            let dayLogs = logs.filter {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if !dayLogs.isEmpty {
                streak += 1
            } else if streak > 0 {
                break
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return streak
    }
    
    /// Get last workout date for a profile
    static func getLastWorkoutDate(for profile: Int) -> Date? {
        let logs = loadLogs().filter { $0.profile == profile }
        return logs.first?.date
    }
    
    /// Get total sets logged for a profile
    static func getTotalSets(for profile: Int) -> Int {
        return loadLogs().filter { $0.profile == profile }.count
    }
    
    /// Load logs from shared UserDefaults (App Group)
    private static func loadLogs() -> [WidgetWorkoutLogEntry] {
        // Try App Group first (for widget access)
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let data = sharedDefaults.data(forKey: storageKey),
           let logs = try? JSONDecoder().decode([WidgetWorkoutLogEntry].self, from: data) {
            return logs
        }
        
        // Fallback to standard UserDefaults (for testing)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let logs = try? JSONDecoder().decode([WidgetWorkoutLogEntry].self, from: data) {
            return logs
        }
        
        return []
    }
}

// Lightweight log entry for widget (matches WorkoutLogEntry structure)
struct WidgetWorkoutLogEntry: Codable {
    let id: UUID
    let date: Date
    let exerciseName: String
    let workoutType: String
    let weight: Double
    let reachedFailure: Bool
    let profile: Int
}

// MARK: - Timeline Provider
struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, totalSets: 142, lastWorkout: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let streak = StreakDataProvider.getCurrentStreak(for: 1)
        let totalSets = StreakDataProvider.getTotalSets(for: 1)
        let lastWorkout = StreakDataProvider.getLastWorkoutDate(for: 1)
        let entry = StreakEntry(date: Date(), streak: streak, totalSets: totalSets, lastWorkout: lastWorkout)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let streak = StreakDataProvider.getCurrentStreak(for: 1)
        let totalSets = StreakDataProvider.getTotalSets(for: 1)
        let lastWorkout = StreakDataProvider.getLastWorkoutDate(for: 1)
        let entry = StreakEntry(date: Date(), streak: streak, totalSets: totalSets, lastWorkout: lastWorkout)
        
        // Update at midnight for streak accuracy
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalSets: Int
    let lastWorkout: Date?
}

// MARK: - Color Definitions (matching app theme)
extension Color {
    static let widgetPrimary = Color(red: 1.0, green: 0.75, blue: 0.0) // Gold/Amber
    static let widgetSecondary = Color(red: 1.0, green: 0.55, blue: 0.0) // Orange
    static let widgetBackground = Color(red: 0.08, green: 0.08, blue: 0.1)
    static let widgetCard = Color(red: 0.15, green: 0.15, blue: 0.18)
}

// MARK: - Widget Views
struct StreakWidgetEntryView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        case .systemSmall:
            systemSmallView
        case .systemMedium:
            systemMediumView
        default:
            systemSmallView
        }
    }
    
    // MARK: - Lock Screen - Circular
    var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
                Text("\(entry.streak)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
        }
    }
    
    // MARK: - Lock Screen - Rectangular
    var accessoryRectangularView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streak) Day Streak")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                if entry.streak > 0 {
                    Text("Keep going strong! 💪")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Start your streak today!")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Lock Screen - Inline
    var accessoryInlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.streak) day streak")
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Home Screen - Small (Modern Gradient Design)
    var systemSmallView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .offset(y: -20)
            
            VStack(spacing: 8) {
                // Flame icon with glow
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 10)
                }
                
                // Streak number
                Text("\(entry.streak)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                
                // Label
                Text(entry.streak == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    // MARK: - Home Screen - Medium (Stats Overview)
    var systemMediumView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 20) {
                // Streak section
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(entry.streak)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(entry.streak == 1 ? "DAY STREAK" : "DAY STREAK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 16)
                
                // Stats section
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(icon: "dumbbell.fill", label: "Total Sets", value: "\(entry.totalSets)", color: .blue)
                    
                    if let lastWorkout = entry.lastWorkout {
                        StatRow(icon: "clock.fill", label: "Last Workout", value: formatRelativeDate(lastWorkout), color: .green)
                    } else {
                        StatRow(icon: "clock.fill", label: "Last Workout", value: "None", color: .gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days)d ago"
        }
    }
}

// MARK: - Supporting Views
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Widget Configuration
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Workout Streak")
        .description("Track your consecutive workout days and stats.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Widget Bundle (entry point)
@main
struct OneRepStrengthWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
    }
}

// MARK: - Previews
#Preview("Circular", as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 7, totalSets: 142, lastWorkout: Date())
}

#Preview("Rectangular", as: .accessoryRectangular) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 14, totalSets: 256, lastWorkout: Date())
}

#Preview("Small", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 21, totalSets: 312, lastWorkout: Date())
}

#Preview("Medium", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), streak: 14, totalSets: 256, lastWorkout: Calendar.current.date(byAdding: .day, value: -1, to: Date()))
}
