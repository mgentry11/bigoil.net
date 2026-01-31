//
//  CloudSyncManager.swift
//  HITCoachPro
//
//  Manages iCloud sync for workout data across devices
//

import Foundation
import CloudKit
import Combine

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    // MARK: - Published Properties
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAvailable = false
    @Published var syncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: "cloudSyncEnabled")
            if syncEnabled {
                performFullSync()
            }
        }
    }

    // MARK: - Private Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()

    // Record Types
    private let workoutLogRecordType = "WorkoutLog"
    private let bodyMeasurementRecordType = "BodyMeasurement"
    private let userSettingsRecordType = "UserSettings"

    // MARK: - Initialization

    init() {
        self.container = CKContainer(identifier: "iCloud.com.onerepstrength.app")
        self.privateDatabase = container.privateCloudDatabase
        self.syncEnabled = UserDefaults.standard.bool(forKey: "cloudSyncEnabled")

        checkCloudStatus()
        loadLastSyncDate()

        // Listen for remote changes
        setupSubscriptions()
    }

    // MARK: - Cloud Status

    func checkCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                    self?.syncError = nil
                case .noAccount:
                    self?.isCloudAvailable = false
                    self?.syncError = "Please sign in to iCloud in Settings"
                case .restricted:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud access is restricted"
                case .couldNotDetermine:
                    self?.isCloudAvailable = false
                    self?.syncError = "Could not determine iCloud status"
                case .temporarilyUnavailable:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud temporarily unavailable"
                @unknown default:
                    self?.isCloudAvailable = false
                    self?.syncError = "Unknown iCloud status"
                }
            }
        }
    }

    // MARK: - Sync Operations

    func performFullSync() {
        guard syncEnabled && isCloudAvailable else { return }
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        Task {
            do {
                // Upload local data
                try await uploadWorkoutLogs()
                try await uploadBodyMeasurements()

                // Download remote data
                try await downloadWorkoutLogs()
                try await downloadBodyMeasurements()

                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.saveLastSyncDate()
                    self.isSyncing = false
                }
            } catch {
                await MainActor.run {
                    self.syncError = error.localizedDescription
                    self.isSyncing = false
                }
            }
        }
    }

    // MARK: - Workout Logs Sync

    private func uploadWorkoutLogs() async throws {
        let logs = WorkoutLogManager.shared.logs

        for log in logs {
            let recordID = CKRecord.ID(recordName: log.id.uuidString)
            let record = CKRecord(recordType: workoutLogRecordType, recordID: recordID)

            record["id"] = log.id.uuidString
            record["date"] = log.date
            record["exerciseName"] = log.exerciseName
            record["workoutType"] = log.workoutType
            record["weight"] = log.weight
            record["reachedFailure"] = log.reachedFailure ? 1 : 0
            record["profile"] = log.profile
            record["rpe"] = log.rpe ?? 0
            record["notes"] = log.notes ?? ""
            record["duration"] = log.duration ?? 0
            record["reps"] = log.reps ?? 0

            do {
                _ = try await privateDatabase.save(record)
            } catch let error as CKError where error.code == .serverRecordChanged {
                // Record already exists, that's fine
                continue
            }
        }
    }

    private func downloadWorkoutLogs() async throws {
        let query = CKQuery(recordType: workoutLogRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (results, _) = try await privateDatabase.records(matching: query)

        var downloadedLogs: [WorkoutLogEntry] = []

        for (_, result) in results {
            if case .success(let record) = result {
                if let log = workoutLogEntry(from: record) {
                    downloadedLogs.append(log)
                }
            }
        }

        // Merge with local data
        await MainActor.run {
            mergeWorkoutLogs(downloadedLogs)
        }
    }

    private func workoutLogEntry(from record: CKRecord) -> WorkoutLogEntry? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date,
              let exerciseName = record["exerciseName"] as? String,
              let workoutType = record["workoutType"] as? String,
              let weight = record["weight"] as? Double,
              let reachedFailureInt = record["reachedFailure"] as? Int,
              let profile = record["profile"] as? Int else {
            return nil
        }

        let rpe = record["rpe"] as? Int
        let notes = record["notes"] as? String
        let duration = record["duration"] as? TimeInterval
        let reps = record["reps"] as? Int

        return WorkoutLogEntry(
            id: id,
            date: date,
            exerciseName: exerciseName,
            workoutType: workoutType,
            weight: weight,
            reachedFailure: reachedFailureInt == 1,
            profile: profile,
            rpe: rpe == 0 ? nil : rpe,
            notes: notes?.isEmpty == true ? nil : notes,
            duration: duration == 0 ? nil : duration,
            reps: reps == 0 ? nil : reps
        )
    }

    private func mergeWorkoutLogs(_ remoteLogs: [WorkoutLogEntry]) {
        let localLogs = WorkoutLogManager.shared.logs
        let localIDs = Set(localLogs.map { $0.id })

        // Add logs that don't exist locally
        for remoteLog in remoteLogs {
            if !localIDs.contains(remoteLog.id) {
                WorkoutLogManager.shared.logs.append(remoteLog)
            }
        }

        // Sort by date (newest first)
        WorkoutLogManager.shared.logs.sort { $0.date > $1.date }
    }

    // MARK: - Body Measurements Sync

    // MARK: - Body Measurements Sync

    private func uploadBodyMeasurements() async throws {
        let measurements = BodyMeasurementsManager.shared.measurements

        for measurement in measurements {
            let recordID = CKRecord.ID(recordName: measurement.id.uuidString)
            let record = CKRecord(recordType: bodyMeasurementRecordType, recordID: recordID)

            record["id"] = measurement.id.uuidString
            record["date"] = measurement.date
            record["bodyWeight"] = measurement.bodyWeight ?? 0
            record["bodyFat"] = measurement.bodyFat ?? 0
            record["chest"] = measurement.chest ?? 0
            record["waist"] = measurement.waist ?? 0
            record["hips"] = measurement.hips ?? 0
            record["bicepsLeft"] = measurement.bicepsLeft ?? 0
            record["bicepsRight"] = measurement.bicepsRight ?? 0
            record["thighLeft"] = measurement.thighLeft ?? 0
            record["thighRight"] = measurement.thighRight ?? 0
            record["calfLeft"] = measurement.calfLeft ?? 0
            record["calfRight"] = measurement.calfRight ?? 0
            record["notes"] = measurement.notes ?? ""
            record["profile"] = measurement.profile

            do {
                _ = try await privateDatabase.save(record)
            } catch let error as CKError where error.code == .serverRecordChanged {
                continue
            }
        }
    }

    private func downloadBodyMeasurements() async throws {
        let query = CKQuery(recordType: bodyMeasurementRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (results, _) = try await privateDatabase.records(matching: query)

        var downloadedMeasurements: [BodyMeasurement] = []

        for (_, result) in results {
            if case .success(let record) = result {
                if let measurement = bodyMeasurement(from: record) {
                    downloadedMeasurements.append(measurement)
                }
            }
        }

        await MainActor.run {
            mergeBodyMeasurements(downloadedMeasurements)
        }
    }

    private func bodyMeasurement(from record: CKRecord) -> BodyMeasurement? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date,
              let profile = record["profile"] as? Int else {
            return nil
        }

        let bodyWeight = record["bodyWeight"] as? Double
        let bodyFat = record["bodyFat"] as? Double
        let chest = record["chest"] as? Double
        let waist = record["waist"] as? Double
        let hips = record["hips"] as? Double
        let bicepsLeft = record["bicepsLeft"] as? Double
        let bicepsRight = record["bicepsRight"] as? Double
        let thighLeft = record["thighLeft"] as? Double
        let thighRight = record["thighRight"] as? Double
        let calfLeft = record["calfLeft"] as? Double
        let calfRight = record["calfRight"] as? Double
        let notes = record["notes"] as? String

        return BodyMeasurement(
            id: id,
            date: date,
            profile: profile,
            bodyWeight: bodyWeight == 0 ? nil : bodyWeight,
            bodyFat: bodyFat == 0 ? nil : bodyFat,
            chest: chest == 0 ? nil : chest,
            waist: waist == 0 ? nil : waist,
            hips: hips == 0 ? nil : hips,
            bicepsLeft: bicepsLeft == 0 ? nil : bicepsLeft,
            bicepsRight: bicepsRight == 0 ? nil : bicepsRight,
            thighLeft: thighLeft == 0 ? nil : thighLeft,
            thighRight: thighRight == 0 ? nil : thighRight,
            calfLeft: calfLeft == 0 ? nil : calfLeft,
            calfRight: calfRight == 0 ? nil : calfRight,
            notes: notes
        )
    }

    private func mergeBodyMeasurements(_ remoteMeasurements: [BodyMeasurement]) {
        let localMeasurements = BodyMeasurementsManager.shared.measurements
        let localIDs = Set(localMeasurements.map { $0.id })

        for remoteMeasurement in remoteMeasurements {
            if !localIDs.contains(remoteMeasurement.id) {
                BodyMeasurementsManager.shared.measurements.append(remoteMeasurement)
            }
        }

        BodyMeasurementsManager.shared.measurements.sort { $0.date > $1.date }
    }

    // MARK: - Subscriptions for Remote Changes

    private func setupSubscriptions() {
        guard syncEnabled else { return }

        // Subscribe to workout log changes
        let workoutSubscription = CKQuerySubscription(
            recordType: workoutLogRecordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "workout-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        workoutSubscription.notificationInfo = notification

        privateDatabase.save(workoutSubscription) { [weak self] _, error in
            if let error = error as? CKError, error.code != .serverRejectedRequest {
                DispatchQueue.main.async {
                    self?.syncError = "Subscription failed: \(error.localizedDescription)"
                }
            }
        }

        // Subscribe to body measurement changes
        let measurementSubscription = CKQuerySubscription(
            recordType: bodyMeasurementRecordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "measurement-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        measurementSubscription.notificationInfo = notification

        privateDatabase.save(measurementSubscription) { [weak self] _, error in
            if let error = error as? CKError, error.code != .serverRejectedRequest {
                DispatchQueue.main.async {
                    self?.syncError = "Subscription failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Persistence

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastCloudSyncDate") as? Date
    }

    // MARK: - Delete All Cloud Data

    func deleteAllCloudData() async throws {
        // Delete workout logs
        let workoutQuery = CKQuery(recordType: workoutLogRecordType, predicate: NSPredicate(value: true))
        let (workoutResults, _) = try await privateDatabase.records(matching: workoutQuery)

        for (recordID, _) in workoutResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }

        // Delete body measurements
        let measurementQuery = CKQuery(recordType: bodyMeasurementRecordType, predicate: NSPredicate(value: true))
        let (measurementResults, _) = try await privateDatabase.records(matching: measurementQuery)

        for (recordID, _) in measurementResults {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
    }

    // MARK: - Format Helpers

    func formattedLastSyncDate() -> String {
        guard let date = lastSyncDate else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
