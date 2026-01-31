//
//  ProfileManager.swift
//  OneRepStrength
//
//  Manages 2 user profiles with persistence
//

import SwiftUI

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [Profile] {
        didSet { save() }
    }
    @Published var selectedProfileIndex: Int {
        didSet { 
            UserDefaults.standard.set(selectedProfileIndex, forKey: "selectedProfile")
        }
    }
    
    private let storageKey = "profiles"
    
    init() {
        // Load selected profile
        selectedProfileIndex = UserDefaults.standard.integer(forKey: "selectedProfile")
        
        // Load profiles from storage
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = saved
        } else {
            profiles = Profile.defaultProfiles
        }
    }
    
    // MARK: - Current Profile
    var currentProfile: Profile {
        get { profiles[selectedProfileIndex] }
        set { profiles[selectedProfileIndex] = newValue }
    }
    
    var profileNames: [String] {
        profiles.map { $0.name }
    }
    
    // MARK: - Exercise Actions
    func startExercise(_ exercise: Exercise) -> Exercise {
        exercise
    }
    
    func logWorkout(exerciseName: String, weight: Double, reachedFailure: Bool) {
        profiles[selectedProfileIndex].logWorkout(
            exerciseName: exerciseName,
            weight: weight,
            reachedFailure: reachedFailure
        )
    }
    
    func updateExerciseWeight(_ exercise: Exercise, weight: Double) {
        if let index = profiles[selectedProfileIndex].exercises.firstIndex(where: { $0.id == exercise.id }) {
            profiles[selectedProfileIndex].exercises[index].lastWeight = weight
        }
    }
    
    func resetWorkout() {
        profiles[selectedProfileIndex].resetWorkout()
    }
    
    func isNewPR(exerciseName: String, weight: Double) -> Bool {
        currentProfile.isNewPR(exerciseName: exerciseName, weight: weight)
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
