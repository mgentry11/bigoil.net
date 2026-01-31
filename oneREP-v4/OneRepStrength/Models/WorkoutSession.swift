//
//  WorkoutSession.swift
//  HITCoachPro
//
//  Tracks the current workout session state - persists until user completes or resets

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var workoutType: String // "workoutA" or "workoutB"
    var startedAt: Date
    var completedExerciseIds: [String] // Array of exercise IDs that are completed in this session
    var exerciseWeights: [String: Double] // exerciseId -> weight used
    var exerciseFailures: [String: Bool] // exerciseId -> reached failure
    var isActive: Bool // True if workout is in progress

    init(id: UUID = UUID(),
         workoutType: String = "workoutA",
         startedAt: Date = Date(),
         completedExerciseIds: [String] = [],
         exerciseWeights: [String: Double] = [:],
         exerciseFailures: [String: Bool] = [:],
         isActive: Bool = true) {
        self.id = id
        self.workoutType = workoutType
        self.startedAt = startedAt
        self.completedExerciseIds = completedExerciseIds
        self.exerciseWeights = exerciseWeights
        self.exerciseFailures = exerciseFailures
        self.isActive = isActive
    }

    // Mark an exercise as completed in this session
    func markExerciseCompleted(exerciseId: UUID, weight: Double, reachedFailure: Bool) {
        let idString = exerciseId.uuidString
        if !completedExerciseIds.contains(idString) {
            completedExerciseIds.append(idString)
        }
        exerciseWeights[idString] = weight
        exerciseFailures[idString] = reachedFailure
    }

    // Check if an exercise is completed in this session
    func isExerciseCompleted(exerciseId: UUID) -> Bool {
        return completedExerciseIds.contains(exerciseId.uuidString)
    }

    // Get weight for an exercise in this session
    func getWeight(for exerciseId: UUID) -> Double? {
        return exerciseWeights[exerciseId.uuidString]
    }

    // Reset only the completion status (keep exercises, weights as last-used defaults)
    func resetCompletion() {
        completedExerciseIds = []
        exerciseFailures = [:]
        startedAt = Date()
    }

    // Full reset - clears everything
    func fullReset() {
        completedExerciseIds = []
        exerciseWeights = [:]
        exerciseFailures = [:]
        startedAt = Date()
    }
}
