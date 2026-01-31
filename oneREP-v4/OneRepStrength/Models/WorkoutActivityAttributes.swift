//
//  WorkoutActivityAttributes.swift
//  OneRepStrength
//
//  Shared attributes for Live Activity
//

import ActivityKit
import SwiftUI

// MARK: - Activity Attributes
/// Defines the static and dynamic data for the workout Live Activity
struct WorkoutActivityAttributes: ActivityAttributes {
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Current workout phase (eccentric, concentric, etc.)
        var phase: String
        /// Seconds remaining in current phase
        var timeRemaining: Int
        /// Total duration of current phase
        var phaseDuration: Int
        /// Whether timer is currently running
        var isRunning: Bool
    }
    
    /// Exercise name (doesn't change during activity)
    var exerciseName: String
    /// Target weight for this exercise
    var weight: Double
}

// MARK: - Phase Colors
extension String {
    var phaseColor: Color {
        switch self.lowercased() {
        case "eccentric", "lower":
            return Color(red: 0.2, green: 0.5, blue: 0.8) // Blue
        case "concentric", "push":
            return Color(red: 0.9, green: 0.5, blue: 0.2) // Orange
        case "final eccentric", "final negative":
            return Color(red: 0.6, green: 0.3, blue: 0.7) // Purple
        case "complete":
            return Color(red: 0.3, green: 0.7, blue: 0.4) // Green
        case "rest", "recover":
            return Color(red: 0.3, green: 0.6, blue: 0.6) // Teal
        case "prep", "get ready":
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        case "position":
            return Color(red: 0.6, green: 0.6, blue: 0.4) // Muted yellow
        default:
            return Color(red: 0.4, green: 0.4, blue: 0.5) // Gray
        }
    }

    var phaseIcon: String {
        switch self.lowercased() {
        case "eccentric", "lower":
            return "arrow.down.circle.fill"
        case "concentric", "push":
            return "arrow.up.circle.fill"
        case "final eccentric", "final negative":
            return "arrow.down.to.line.circle.fill"
        case "complete":
            return "checkmark.circle.fill"
        case "rest", "recover":
            return "bed.double.circle.fill"
        case "prep", "get ready":
            return "figure.stand"
        case "position":
            return "hand.raised.circle.fill"
        default:
            return "timer"
        }
    }
}
