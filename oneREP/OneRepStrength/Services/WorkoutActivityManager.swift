//
//  WorkoutActivityManager.swift
//  OneRepStrength
//
//  Manages Live Activity lifecycle
//

import ActivityKit
import Foundation

// MARK: - Activity Manager
/// Helper class to manage Live Activity lifecycle
class WorkoutActivityManager {
    static let shared = WorkoutActivityManager()
    
    private var currentActivity: Activity<WorkoutActivityAttributes>?
    
    /// Start a new Live Activity for a workout
    func startActivity(exerciseName: String, weight: Double, phase: String, duration: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        let attributes = WorkoutActivityAttributes(
            exerciseName: exerciseName,
            weight: weight
        )
        
        let state = WorkoutActivityAttributes.ContentState(
            phase: phase,
            timeRemaining: duration,
            phaseDuration: duration,
            isRunning: true
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    /// Update the Live Activity with new state
    func updateActivity(phase: String, timeRemaining: Int, phaseDuration: Int, isRunning: Bool) {
        Task {
            let state = WorkoutActivityAttributes.ContentState(
                phase: phase,
                timeRemaining: timeRemaining,
                phaseDuration: phaseDuration,
                isRunning: isRunning
            )
            
            await currentActivity?.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }
    
    /// End the Live Activity
    func endActivity(phase: String = "Complete") {
        Task {
            let finalState = WorkoutActivityAttributes.ContentState(
                phase: phase,
                timeRemaining: 0,
                phaseDuration: 0,
                isRunning: false
            )
            
            await currentActivity?.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            currentActivity = nil
        }
    }
}
