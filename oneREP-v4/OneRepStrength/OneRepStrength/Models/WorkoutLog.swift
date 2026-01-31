//
//  WorkoutLog.swift
//  OneRepStrength
//
//  Historical workout entry for tracking progress
//

import Foundation

struct WorkoutLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    let exerciseName: String
    let weight: Double
    let reachedFailure: Bool
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseName: String,
        weight: Double,
        reachedFailure: Bool,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.weight = weight
        self.reachedFailure = reachedFailure
        self.notes = notes
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
