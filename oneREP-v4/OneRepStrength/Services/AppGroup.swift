
//
//  AppGroup.swift
//  OneRepStrength
//
//  Manages shared data access for App Groups (Widgets, Watch Support)
//

import Foundation
import WidgetKit

struct AppGroup {
    // REPLACE WITH YOUR ACTUAL APP GROUP IDENTIFIER
    static let identifier = "group.com.markgentry.onerepstrength"
    
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
    
    // Helper to shared data path
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
    
    // MARK: - Widget Data
    static var widgetSummary: WidgetSummary? {
        get {
            if let data = defaults.data(forKey: "widgetSummary"),
               let summary = try? JSONDecoder().decode(WidgetSummary.self, from: data) {
                return summary
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "widgetSummary")
                // Reload widget timelines
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

// Data struct optimized for Widgets (prevent reading full log history)
struct WidgetSummary: Codable {
    let streak: Int
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let lastWorkoutDate: Date?
    let lastWorkoutType: String?
    let totalVolume: Double
    let primaryProfile: Int
}
