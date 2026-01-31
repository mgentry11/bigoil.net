//
//  WorkoutTemplate.swift
//  HITCoachPro
//
//  Stores reusable workout routines that users can save, organize, and share
//

import Foundation

struct WorkoutTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var exercises: [TemplateExercise]
    let createdAt: Date
    var lastUsedAt: Date?
    var profile: Int
    var isBuiltIn: Bool  // For default Workout A/B templates

    init(id: UUID = UUID(),
         name: String,
         exercises: [TemplateExercise],
         createdAt: Date = Date(),
         lastUsedAt: Date? = nil,
         profile: Int,
         isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.profile = profile
        self.isBuiltIn = isBuiltIn
    }

    // Create template from current workout exercises
    static func fromExercises(_ exercises: [Exercise], name: String, profile: Int) -> WorkoutTemplate {
        let templateExercises = exercises.map { exercise in
            TemplateExercise(
                name: exercise.name,
                targetWeight: exercise.lastWeight,
                iconName: exercise.iconName,
                audioFileName: exercise.audioFileName
            )
        }
        return WorkoutTemplate(
            name: name,
            exercises: templateExercises,
            profile: profile
        )
    }

    // Create template from workout log entries (for a specific day)
    static func fromLogEntries(_ entries: [WorkoutLogEntry], name: String, profile: Int) -> WorkoutTemplate {
        // Remove duplicates, keeping the last entry for each exercise
        var exerciseDict: [String: WorkoutLogEntry] = [:]
        for entry in entries {
            exerciseDict[entry.exerciseName] = entry
        }

        let templateExercises = exerciseDict.values.map { entry in
            TemplateExercise(
                name: entry.exerciseName,
                targetWeight: entry.weight,
                iconName: "dumbbell.png", // Default icon for imported exercises
                audioFileName: "exercise_custom"
            )
        }

        return WorkoutTemplate(
            name: name,
            exercises: templateExercises,
            profile: profile
        )
    }

    // Convert to Exercise array for loading into WorkoutManager
    func toExercises() -> [Exercise] {
        return exercises.map { templateExercise in
            Exercise(
                name: templateExercise.name,
                iconName: templateExercise.iconName,
                audioFileName: templateExercise.audioFileName,
                lastWeight: templateExercise.targetWeight
            )
        }
    }
}

// MARK: - Template Exercise
struct TemplateExercise: Codable, Identifiable {
    let id: UUID
    var name: String
    var targetWeight: Double?
    var iconName: String
    var audioFileName: String

    init(id: UUID = UUID(),
         name: String,
         targetWeight: Double? = nil,
         iconName: String = "dumbbell.png",
         audioFileName: String = "exercise_custom") {
        self.id = id
        self.name = name
        self.targetWeight = targetWeight
        self.iconName = iconName
        self.audioFileName = audioFileName
    }
}

// MARK: - Shareable Template (for export/import)
struct ShareableTemplate: Codable {
    let version: Int = 1
    let name: String
    let exercises: [TemplateExercise]
    let exportedAt: Date

    init(from template: WorkoutTemplate) {
        self.name = template.name
        self.exercises = template.exercises
        self.exportedAt = Date()
    }

    func toTemplate(profile: Int) -> WorkoutTemplate {
        return WorkoutTemplate(
            name: name,
            exercises: exercises,
            profile: profile
        )
    }
}
