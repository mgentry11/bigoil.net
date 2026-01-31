//
//  Exercise.swift
//  OneRepStrength
//
//  Data model for exercises with weight tracking
//

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var lastWeight: Double?
    var isCompleted: Bool
    var isBodyweight: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "dumbbell.fill",
        lastWeight: Double? = nil,
        isCompleted: Bool = false,
        isBodyweight: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.lastWeight = lastWeight
        self.isCompleted = isCompleted
        self.isBodyweight = isBodyweight
    }
}

// MARK: - Default Exercises
extension Exercise {
    static let defaultWorkoutA: [Exercise] = [
        Exercise(name: "Leg Press", iconName: "figure.strengthtraining.traditional"),
        Exercise(name: "Pulldown", iconName: "figure.climbing"),
        Exercise(name: "Chest Press", iconName: "figure.boxing"),
        Exercise(name: "Overhead Press", iconName: "figure.arms.open"),
        Exercise(name: "Seated Row", iconName: "figure.rower"),
        Exercise(name: "Leg Curl", iconName: "figure.walk"),
        Exercise(name: "Bicep Curl", iconName: "figure.mixed.cardio"),
        Exercise(name: "Tricep Extension", iconName: "figure.cooldown")
    ]
    
    static let defaultWorkoutB: [Exercise] = [
        Exercise(name: "Leg Extension", iconName: "figure.walk"),
        Exercise(name: "Cable Row", iconName: "figure.rower"),
        Exercise(name: "Incline Press", iconName: "figure.boxing"),
        Exercise(name: "Lateral Raise", iconName: "figure.arms.open"),
        Exercise(name: "Calf Raise", iconName: "figure.stand"),
        Exercise(name: "Preacher Curl", iconName: "figure.mixed.cardio"),
        Exercise(name: "Tricep Pushdown", iconName: "figure.cooldown"),
        Exercise(name: "Ab Machine", iconName: "figure.core.training")
    ]
}
