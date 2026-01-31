//
//  WorkoutLog.swift
//  HITCoachPro
//
//  Stores historical workout data for tracking progress over time

import Foundation

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
    
    /// App Group identifier for sharing data with widgets
    private let appGroupIdentifier = "group.com.onerepstrength.shared"

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

    /// Get estimated 1RM for an exercise
    func getEstimated1RM(for exerciseName: String, profile: Int) -> Double? {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        let estimated1RMs = exerciseLogs.compactMap { $0.estimated1RM }
        return estimated1RMs.max()
    }

    /// Get average RPE for an exercise
    func getAverageRPE(for exerciseName: String, profile: Int) -> Double? {
        let exerciseLogs = getLogs(for: exerciseName, profile: profile)
        let rpes = exerciseLogs.compactMap { $0.rpe }
        guard !rpes.isEmpty else { return nil }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }

    /// Get all unique exercise names for a profile
    func getUniqueExercises(for profile: Int) -> [String] {
        let exerciseNames = getLogs(for: profile).map { $0.exerciseName }
        return Array(Set(exerciseNames)).sorted()
    }

    /// Get personal records for all exercises
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

    /// Check if a weight is a new PR for an exercise
    func isNewPR(exerciseName: String, weight: Double, profile: Int) -> Bool {
        guard let currentMax = getMaxWeight(for: exerciseName, profile: profile) else {
            return true // First time logging this exercise
        }
        return weight > currentMax
    }

    /// Get total volume (weight x sets) for a date range
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

    // MARK: - Persistence

    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            // Save to standard UserDefaults (main app)
            UserDefaults.standard.set(data, forKey: storageKey)
            
            // Also save to App Group shared storage (for widgets)
            if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                sharedDefaults.set(data, forKey: storageKey)
            }
        }
    }

    private func loadLogs() {
        // Try loading from standard UserDefaults first
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedLogs = try? JSONDecoder().decode([WorkoutLogEntry].self, from: data) {
            logs = savedLogs
            // Sync to shared storage if not already there
            syncToSharedStorage()
        }
    }
    
    /// Sync current logs to App Group shared storage for widget access
    private func syncToSharedStorage() {
        if let data = try? JSONEncoder().encode(logs),
           let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            sharedDefaults.set(data, forKey: storageKey)
        }
    }
}
