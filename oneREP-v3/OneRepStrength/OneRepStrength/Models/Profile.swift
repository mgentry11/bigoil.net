//
//  Profile.swift
//  OneRepStrength
//
//  User profile with separate exercises and workout history
//

import Foundation

struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    var workoutLogs: [WorkoutLog]
    
    init(
        id: UUID = UUID(),
        name: String,
        exercises: [Exercise] = Exercise.defaultWorkoutA,
        workoutLogs: [WorkoutLog] = []
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.workoutLogs = workoutLogs
    }
    
    // MARK: - Stats
    var totalSets: Int {
        workoutLogs.count
    }
    
    var totalVolume: Double {
        workoutLogs.reduce(0) { $0 + $1.weight }
    }
    
    var completedExercises: Int {
        exercises.filter { $0.isCompleted }.count
    }
    
    // MARK: - PRs
    func maxWeight(for exerciseName: String) -> Double? {
        workoutLogs
            .filter { $0.exerciseName == exerciseName }
            .map { $0.weight }
            .max()
    }
    
    func isNewPR(exerciseName: String, weight: Double) -> Bool {
        guard let currentMax = maxWeight(for: exerciseName) else { return true }
        return weight > currentMax
    }
    
    // MARK: - Mutations
    mutating func logWorkout(exerciseName: String, weight: Double, reachedFailure: Bool) {
        let log = WorkoutLog(
            exerciseName: exerciseName,
            weight: weight,
            reachedFailure: reachedFailure
        )
        workoutLogs.insert(log, at: 0)
        
        // Update exercise weight
        if let index = exercises.firstIndex(where: { $0.name == exerciseName }) {
            exercises[index].lastWeight = weight
            exercises[index].isCompleted = true
        }
    }
    
    mutating func resetWorkout() {
        for i in exercises.indices {
            exercises[i].isCompleted = false
        }
    }
}

// MARK: - Default Profiles
extension Profile {
    static let defaultProfiles: [Profile] = [
        Profile(name: "Profile 1", exercises: Exercise.defaultWorkoutA),
        Profile(name: "Profile 2", exercises: Exercise.defaultWorkoutB)
    ]
}
