//
//  HealthKitManager.swift
//  HITCoachPro
//
//  Manages Apple Health integration for syncing workouts

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var isAvailable = false

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Types we want to write to HealthKit
    private var typesToWrite: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        types.insert(HKObjectType.workoutType())
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let bodyFatPercentage = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFatPercentage)
        }
        return types
    }

    /// Types we want to read from HealthKit
    private var typesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let bodyFatPercentage = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFatPercentage)
        }
        return types
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable else {
            completion(false, nil)
            return
        }

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success, error)
            }
        }
    }

    func checkAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }

        // Check if we have authorization for workouts
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Save Workout

    func saveWorkout(
        duration: TimeInterval,
        totalWeight: Double,
        exerciseCount: Int,
        startDate: Date,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isAvailable && isAuthorized else {
            completion(false, nil)
            return
        }

        let endDate = startDate.addingTimeInterval(duration)

        // Estimate calories burned (rough estimate for strength training)
        // ~3-6 calories per minute for moderate strength training
        let caloriesBurned = duration / 60.0 * 4.5

        // Use HKWorkoutBuilder (iOS 17+ recommended approach)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        builder.beginCollection(withStart: startDate) { [weak self] success, error in
            guard success else {
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }

            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned)
                let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: startDate, end: endDate)
                builder.add([energySample]) { _, _ in }
            }

            builder.endCollection(withEnd: endDate) { success, error in
                guard success else {
                    DispatchQueue.main.async {
                        completion(false, error)
                    }
                    return
                }

                builder.finishWorkout { workout, error in
                    DispatchQueue.main.async {
                        completion(workout != nil, error)
                    }
                }
            }
        }
    }

    // MARK: - Save Body Measurements

    func saveBodyWeight(_ weight: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable && isAuthorized else {
            completion(false, nil)
            return
        }

        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, nil)
            return
        }

        // Convert lbs to kg for HealthKit (HealthKit uses metric)
        let weightInKg = weight * 0.453592
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightInKg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func saveBodyFatPercentage(_ percentage: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable && isAuthorized else {
            completion(false, nil)
            return
        }

        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            completion(false, nil)
            return
        }

        // HealthKit expects body fat as a decimal (0.0 - 1.0)
        let decimalPercentage = percentage / 100.0
        let quantity = HKQuantity(unit: .percent(), doubleValue: decimalPercentage)
        let sample = HKQuantitySample(type: bodyFatType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // MARK: - Read Body Measurements

    func getLatestBodyWeight(completion: @escaping (Double?) -> Void) {
        guard isAvailable else {
            completion(nil)
            return
        }

        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                // Convert kg to lbs
                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let weightInLbs = weightInKg / 0.453592
                completion(weightInLbs)
            }
        }

        healthStore.execute(query)
    }
}
