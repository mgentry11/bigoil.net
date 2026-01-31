//
//  BodyMeasurements.swift
//  HITCoachPro
//
//  Track body weight and measurements over time

import Foundation

struct BodyMeasurement: Codable, Identifiable {
    let id: UUID
    let date: Date
    let profile: Int
    var bodyWeight: Double? // in lbs
    var bodyFat: Double? // percentage
    var chest: Double? // inches
    var waist: Double? // inches
    var hips: Double? // inches
    var bicepsLeft: Double? // inches
    var bicepsRight: Double? // inches
    var thighLeft: Double? // inches
    var thighRight: Double? // inches
    var calfLeft: Double? // inches
    var calfRight: Double? // inches
    var notes: String?

    init(id: UUID = UUID(),
         date: Date = Date(),
         profile: Int,
         bodyWeight: Double? = nil,
         bodyFat: Double? = nil,
         chest: Double? = nil,
         waist: Double? = nil,
         hips: Double? = nil,
         bicepsLeft: Double? = nil,
         bicepsRight: Double? = nil,
         thighLeft: Double? = nil,
         thighRight: Double? = nil,
         calfLeft: Double? = nil,
         calfRight: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.profile = profile
        self.bodyWeight = bodyWeight
        self.bodyFat = bodyFat
        self.chest = chest
        self.waist = waist
        self.hips = hips
        self.bicepsLeft = bicepsLeft
        self.bicepsRight = bicepsRight
        self.thighLeft = thighLeft
        self.thighRight = thighRight
        self.calfLeft = calfLeft
        self.calfRight = calfRight
        self.notes = notes
    }
}

class BodyMeasurementsManager: ObservableObject {
    static let shared = BodyMeasurementsManager()

    @Published var measurements: [BodyMeasurement] = []

    private let storageKey = "bodyMeasurements"

    init() {
        loadMeasurements()
    }

    // MARK: - Measurement Management

    func addMeasurement(_ measurement: BodyMeasurement) {
        measurements.insert(measurement, at: 0)
        saveMeasurements()
    }

    func getMeasurements(for profile: Int) -> [BodyMeasurement] {
        return measurements.filter { $0.profile == profile }.sorted { $0.date > $1.date }
    }

    func getLatestMeasurement(for profile: Int) -> BodyMeasurement? {
        return getMeasurements(for: profile).first
    }

    func deleteMeasurement(_ measurement: BodyMeasurement) {
        measurements.removeAll { $0.id == measurement.id }
        saveMeasurements()
    }

    // MARK: - Weight Tracking

    func getWeightHistory(for profile: Int, last: Int = 30) -> [(date: Date, weight: Double)] {
        let profileMeasurements = getMeasurements(for: profile)
        return profileMeasurements
            .prefix(last)
            .compactMap { measurement -> (Date, Double)? in
                guard let weight = measurement.bodyWeight else { return nil }
                return (measurement.date, weight)
            }
            .reversed()
    }

    func getLatestWeight(for profile: Int) -> Double? {
        return getMeasurements(for: profile).first?.bodyWeight
    }

    func getWeightChange(for profile: Int, days: Int = 30) -> Double? {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let profileMeasurements = getMeasurements(for: profile)
        guard let latestWeight = profileMeasurements.first?.bodyWeight else { return nil }

        // Find measurement closest to start date
        let olderMeasurements = profileMeasurements.filter { $0.date <= startDate }
        guard let oldestWeight = olderMeasurements.first?.bodyWeight else {
            // If no measurement that old, use the oldest available
            guard let oldestAvailable = profileMeasurements.last?.bodyWeight else { return nil }
            return latestWeight - oldestAvailable
        }

        return latestWeight - oldestWeight
    }

    // MARK: - Body Fat Tracking

    func getBodyFatHistory(for profile: Int, last: Int = 30) -> [(date: Date, bodyFat: Double)] {
        let profileMeasurements = getMeasurements(for: profile)
        return profileMeasurements
            .prefix(last)
            .compactMap { measurement -> (Date, Double)? in
                guard let bf = measurement.bodyFat else { return nil }
                return (measurement.date, bf)
            }
            .reversed()
    }

    // MARK: - Persistence

    private func saveMeasurements() {
        if let data = try? JSONEncoder().encode(measurements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadMeasurements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([BodyMeasurement].self, from: data) {
            measurements = saved
        }
    }
}
