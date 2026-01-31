
//
//  WorkoutLogManager.swift
//  HITCoachPro
//
//  Stores historical workout data for tracking progress over time
//

import Foundation
import WidgetKit

// MARK: - Widget Data Structures (for App Group sharing)

struct WidgetSummary: Codable {
    let streak: Int
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let lastWorkoutDate: Date?
    let lastWorkoutType: String?
    let totalVolume: Double
    let primaryProfile: Int
}

struct AppGroup {
    static let identifier = "group.com.markgentry.onerepstrength"
    
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
    
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
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct WorkoutLogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let exerciseName: String
    let workoutType: String // "A" or "B"
    let weight: Double
    let reachedFailure: Bool
    let profile: Int
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var notes: String?
    var duration: TimeInterval? // Set duration in seconds
    var reps: Int? // Number of reps (for 1RM calculation)

    init(id: UUID = UUID(),
         date: Date = Date(),
         exerciseName: String,
         workoutType: String,
         weight: Double,
         reachedFailure: Bool,
         profile: Int,
         rpe: Int? = nil,
         notes: String? = nil,
         duration: TimeInterval? = nil,
         reps: Int? = nil) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.workoutType = workoutType
        self.weight = weight
        self.reachedFailure = reachedFailure
        self.profile = profile
        self.rpe = rpe
        self.notes = notes
        self.duration = duration
        self.reps = reps
    }

    // Calculate estimated 1RM using Brzycki formula
    var estimated1RM: Double? {
        guard let reps = reps, reps > 0, reps <= 12, weight > 0 else { return nil }
        if reps == 1 { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
}

class WorkoutLogManager: ObservableObject {
    static let shared = WorkoutLogManager()

    @Published var logs: [WorkoutLogEntry] = []

    private let storageKey = "workoutLogs"
    
    init() {
        loadLogs()
    }

    // MARK: - Log Management

    func addLog(exerciseName: String, workoutType: String, weight: Double, reachedFailure: Bool, profile: Int, rpe: Int? = nil, notes: String? = nil, duration: TimeInterval? = nil, reps: Int? = nil) {
        let entry = WorkoutLogEntry(
            exerciseName: exerciseName,
            workoutType: workoutType,
            weight: weight,
            reachedFailure: reachedFailure,
            profile: profile,
            rpe: rpe,
            notes: notes,
            duration: duration,
            reps: reps
        )
        logs.insert(entry, at: 0)
        saveLogs()
    }

    func getLogs(for profile: Int) -> [WorkoutLogEntry] {
        return logs.filter { $0.profile == profile }
    }

    func getLogs(for exerciseName: String, profile: Int) -> [WorkoutLogEntry] {
        return logs.filter { $0.exerciseName == exerciseName && $0.profile == profile }
    }

    func getRecentLogs(limit: Int = 50, profile: Int) -> [WorkoutLogEntry] {
        return Array(getLogs(for: profile).prefix(limit))
    }

    func clearLogs(for profile: Int) {
        logs.removeAll { $0.profile == profile }
        saveLogs()
    }

    // MARK: - Stats

    func getMaxWeight(for exerciseName: String, profile: Int) -> Double? {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        return exerciseLogs.map { $0.weight }.max()
    }

    func getLastWeight(for exerciseName: String, profile: Int) -> Double? {
        return getLogs(for: exerciseName, profile: profile).first?.weight
    }

    func getTotalSets(for profile: Int) -> Int {
        return getLogs(for: profile).count
    }

    func getTotalSetsToday(for profile: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return getLogs(for: profile).filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }.count
    }

    func getFailureRate(for exerciseName: String, profile: Int) -> Double {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        guard !exerciseLogs.isEmpty else { return 0 }
        let failureCount = exerciseLogs.filter { $0.reachedFailure }.count
        return Double(failureCount) / Double(exerciseLogs.count) * 100
    }

    func getProgressData(for exerciseName: String, profile: Int, last: Int = 10) -> [(date: Date, weight: Double)] {
        let exerciseLogs = Array(getLogs(for: exerciseName, profile: profile).prefix(last))
        return exerciseLogs.reversed().map { ($0.date, $0.weight) }
    }

    // MARK: - Advanced Stats

    func getEstimated1RM(for exerciseName: String, profile: Int) -> Double? {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        let estimated1RMs = exerciseLogs.compactMap { $0.estimated1RM }
        return estimated1RMs.max()
    }

    func getAverageRPE(for exerciseName: String, profile: Int) -> Double? {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        let rpes = exerciseLogs.compactMap { $0.rpe }
        guard !rpes.isEmpty else { return nil }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }

    func getUniqueExercises(for profile: Int) -> [String] {
        let exerciseNames = getLogs(for: profile).map { $0.exerciseName }
        return Array(Set(exerciseNames)).sorted()
    }

    func getPersonalRecords(for profile: Int) -> [String: Double] {
        var prs: [String: Double] = [:]
        let exercises = getUniqueExercises(for: profile)
        for exercise in exercises {
            if let maxWeight = getMaxWeight(for: exercise, profile: profile) {
                prs[exercise] = maxWeight
            }
        }
        return prs
    }

    func isNewPR(exerciseName: String, weight: Double, profile: Int) -> Bool {
        guard let currentMax = getMaxWeight(for: exerciseName, profile: profile) else {
            return true
        }
        return weight > currentMax
    }

    func getTotalVolume(for profile: Int, days: Int = 7) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentLogs = getLogs(for: profile).filter { $0.date >= startDate }
        return recentLogs.reduce(0) { $0 + $1.weight }
    }

    // MARK: - CSV Export

    func exportToCSV(for profile: Int) -> String {
        var csv = "Date,Exercise,Workout,Weight (lbs),Reps,RPE,Reached Failure,Notes,Estimated 1RM\n"

        let profileLogs = getLogs(for: profile)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for log in profileLogs {
            let date = dateFormatter.string(from: log.date)
            let reps = log.reps.map { String($0) } ?? ""
            let rpe = log.rpe.map { String($0) } ?? ""
            let notes = log.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            let estimated1RM = log.estimated1RM.map { String(format: "%.1f", $0) } ?? ""

            csv += "\(date),\(log.exerciseName),\(log.workoutType),\(log.weight),\(reps),\(rpe),\(log.reachedFailure),\(notes),\(estimated1RM)\n"
        }

        return csv
    }
    
    // MARK: - Widget Update
    
    private func updateWidgetSummary() {
        // We track stats for Profile 1 by default for widgets
        let profile = 1
        let profileLogs = getLogs(for: profile)
        
        // Calculate Streak
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Find the last workout date to start streak check from
        // If last workout was today, start today. If yesterday, start yesterday.
        // If older, streak is 0.
        
        let uniqueDates = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = uniqueDates.sorted(by: >)
        
        if let lastDate = sortedDates.first {
            if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
                 // Calculate streak
                 for i in 0..<365 {
                     let targetDate = calendar.date(byAdding: .day, value: -i, to: checkDate)!
                     if uniqueDates.contains(calendar.startOfDay(for: targetDate)) {
                         streak += 1
                     } else if i == 0 && !uniqueDates.contains(calendar.startOfDay(for: targetDate)) {
                         // Today not done yet, don't break streak if yesterday was done
                         continue
                     } else {
                         break
                     }
                 }
            }
        }
        
        // Stats
        let totalWorkouts = uniqueDates.count
        
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyWorkouts = uniqueDates.filter { $0 >= calendar.startOfDay(for: weekAgo) }.count
        
        let lastWorkout = profileLogs.first
        let totalVolume = getTotalVolume(for: profile)
        
        let summary = WidgetSummary(
            streak: streak,
            totalWorkouts: totalWorkouts,
            weeklyWorkouts: weeklyWorkouts,
            lastWorkoutDate: lastWorkout?.date,
            lastWorkoutType: lastWorkout?.workoutType,
            totalVolume: totalVolume,
            primaryProfile: profile
        )
        
        AppGroup.widgetSummary = summary
    }

    // MARK: - Persistence

    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            // Save to shared App Group storage
            AppGroup.defaults.set(data, forKey: storageKey)
            
            // Backup to standard
            UserDefaults.standard.set(data, forKey: storageKey)
            
            // Update Widget Summary
            updateWidgetSummary()
        }
    }

    private func loadLogs() {
        // Try loading from shared storage first (primary source of truth)
        if let data = AppGroup.defaults.data(forKey: storageKey),
           let savedLogs = try? JSONDecoder().decode([WorkoutLogEntry].self, from: data) {
            logs = savedLogs
        } 
        // Fallback: Try loading from standard (migration)
        else if let data = UserDefaults.standard.data(forKey: storageKey),
                let savedLogs = try? JSONDecoder().decode([WorkoutLogEntry].self, from: data) {
            logs = savedLogs
            // Instant migrate/sync to shared
            saveLogs()
        }
    }
}
