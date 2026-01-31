// PartnerWorkoutManager.swift
// Manages partner workout sessions where two users alternate with their own routines

import Foundation
import SwiftUI

class PartnerWorkoutManager: ObservableObject {
    static let shared = PartnerWorkoutManager()
    
    @Published var isPartnerModeActive: Bool = false
    @Published var currentPartner: Int = 1  // 1 or 2
    @Published var partner1Profile: Int = 1
    @Published var partner2Profile: Int = 2
    
    // Each partner's workout state
    @Published var partner1CurrentExerciseIndex: Int = 0
    @Published var partner2CurrentExerciseIndex: Int = 0
    
    // Separate exercise completion tracking
    @Published var partner1CompletedExercises: Set<Int> = []
    @Published var partner2CompletedExercises: Set<Int> = []
    
    // SEPARATE WORKOUTS for each partner
    @Published var partner1Workout: Workout?
    @Published var partner2Workout: Workout?
    
    private let isPartnerModeKey = "isPartnerModeActive"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Partner Mode Control
    
    func startPartnerWorkout(partner1: Int, partner2: Int, initialWorkout: Workout) {
        partner1Profile = partner1
        partner2Profile = partner2
        currentPartner = 1
        isPartnerModeActive = true
        partner1CurrentExerciseIndex = 0
        partner2CurrentExerciseIndex = 0
        partner1CompletedExercises = []
        partner2CompletedExercises = []
        
        // Both partners start with a COPY of the initial workout
        partner1Workout = deepCopyWorkout(initialWorkout)
        partner2Workout = deepCopyWorkout(initialWorkout)
        
        saveSettings()
    }
    
    func endPartnerWorkout() {
        isPartnerModeActive = false
        currentPartner = 1
        partner1Workout = nil
        partner2Workout = nil
        saveSettings()
    }
    
    func switchPartner(workoutManager: WorkoutManager) {
        // Save current partner's workout state
        if currentPartner == 1 {
            partner1Workout = deepCopyWorkout(workoutManager.currentWorkout)
        } else {
            partner2Workout = deepCopyWorkout(workoutManager.currentWorkout)
        }
        
        // Switch to other partner
        currentPartner = currentPartner == 1 ? 2 : 1
        
        // Load new partner's workout
        if let workout = currentPartner == 1 ? partner1Workout : partner2Workout {
            workoutManager.currentWorkout = workout
        }
        
        // Switch profile
        workoutManager.selectProfile(currentPartner == 1 ? partner1Profile : partner2Profile)
    }
    
    /// Save current workout state before switching
    func saveCurrentPartnerWorkout(_ workout: Workout) {
        if currentPartner == 1 {
            partner1Workout = deepCopyWorkout(workout)
        } else {
            partner2Workout = deepCopyWorkout(workout)
        }
    }
    
    /// Get the current partner's workout
    func getCurrentPartnerWorkout() -> Workout? {
        return currentPartner == 1 ? partner1Workout : partner2Workout
    }
    
    /// Deep copy a workout to prevent reference sharing
    private func deepCopyWorkout(_ workout: Workout) -> Workout {
        return Workout(
            id: workout.id,
            name: workout.name,
            exercises: workout.exercises.map { exercise in
                var copy = Exercise(
                    id: UUID(), // New ID for the copy
                    name: exercise.name,
                    iconName: exercise.iconName,
                    audioFileName: exercise.audioFileName,
                    lastWeight: exercise.lastWeight,
                    isBodyweight: exercise.isBodyweight
                )
                copy.reachedFailure = exercise.reachedFailure
                copy.isCompleted = exercise.isCompleted
                copy.lastDuration = exercise.lastDuration
                return copy
            }
        )
    }
    
    func getCurrentPartnerProfile() -> Int {
        return currentPartner == 1 ? partner1Profile : partner2Profile
    }
    
    func getOtherPartnerProfile() -> Int {
        return currentPartner == 1 ? partner2Profile : partner1Profile
    }
    
    // MARK: - Exercise Progress
    
    func markExerciseComplete(for partner: Int, exerciseIndex: Int) {
        if partner == 1 {
            partner1CompletedExercises.insert(exerciseIndex)
        } else {
            partner2CompletedExercises.insert(exerciseIndex)
        }
    }
    
    func isExerciseComplete(for partner: Int, exerciseIndex: Int) -> Bool {
        if partner == 1 {
            return partner1CompletedExercises.contains(exerciseIndex)
        } else {
            return partner2CompletedExercises.contains(exerciseIndex)
        }
    }
    
    func advanceExercise(for partner: Int) {
        if partner == 1 {
            partner1CurrentExerciseIndex += 1
        } else {
            partner2CurrentExerciseIndex += 1
        }
    }
    
    func currentExerciseIndex(for partner: Int) -> Int {
        return partner == 1 ? partner1CurrentExerciseIndex : partner2CurrentExerciseIndex
    }
    
    func completedCount(for partner: Int) -> Int {
        return partner == 1 ? partner1CompletedExercises.count : partner2CompletedExercises.count
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        UserDefaults.standard.set(isPartnerModeActive, forKey: isPartnerModeKey)
        UserDefaults.standard.set(partner1Profile, forKey: "partner1Profile")
        UserDefaults.standard.set(partner2Profile, forKey: "partner2Profile")
    }
    
    private func loadSettings() {
        isPartnerModeActive = UserDefaults.standard.bool(forKey: isPartnerModeKey)
        partner1Profile = UserDefaults.standard.integer(forKey: "partner1Profile")
        partner2Profile = UserDefaults.standard.integer(forKey: "partner2Profile")
        
        // Default profiles if not set
        if partner1Profile == 0 { partner1Profile = 1 }
        if partner2Profile == 0 { partner2Profile = 2 }
    }
}
