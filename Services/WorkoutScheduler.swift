//
//  WorkoutScheduler.swift
//  OneRepStrength
//
//  Manages workout scheduling and notifications based on experience level

import Foundation
import UserNotifications

class WorkoutScheduler: ObservableObject {
    static let shared = WorkoutScheduler()

    @Published var nextWorkoutDate: Date?
    @Published var nextWorkoutType: String = "A"
    @Published var notificationsEnabled: Bool = false
    @Published var preferredWorkoutTime: DateComponents = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return components
    }()

    private let notificationCenter = UNUserNotificationCenter.current()

    init() {
        loadSettings()
        checkNotificationStatus()
    }

    // MARK: - Notification Permissions

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted {
                    self.saveSettings()
                }
                completion(granted)
            }
        }
    }

    func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Workout Scheduling

    /// Calculate next workout date based on experience level and last workout
    func calculateNextWorkout(
        experienceLevel: UserProfile.ExperienceLevel,
        lastWorkoutDate: Date?,
        lastWorkoutType: String?,
        profile: Int
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get recommended days per week based on experience
        let workoutsPerWeek: Int
        switch experienceLevel {
        case .beginner:
            workoutsPerWeek = 2
        case .intermediate:
            workoutsPerWeek = 2
        case .advanced:
            workoutsPerWeek = 3
        }

        // Calculate days between workouts
        let daysBetweenWorkouts = 7 / workoutsPerWeek

        // Determine next workout date
        let nextDate: Date
        if let lastDate = lastWorkoutDate {
            let lastWorkoutDay = calendar.startOfDay(for: lastDate)

            // If last workout was today, schedule for next workout day
            if calendar.isDate(lastWorkoutDay, inSameDayAs: today) {
                nextDate = calendar.date(byAdding: .day, value: daysBetweenWorkouts, to: today) ?? today
            } else {
                // Calculate next workout based on rest days
                let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkoutDay, to: today).day ?? 0

                if daysSinceLastWorkout >= daysBetweenWorkouts {
                    // Rest period complete, workout today
                    nextDate = today
                } else {
                    // Still in rest period
                    let daysUntilNextWorkout = daysBetweenWorkouts - daysSinceLastWorkout
                    nextDate = calendar.date(byAdding: .day, value: daysUntilNextWorkout, to: today) ?? today
                }
            }
        } else {
            // No previous workout, start today
            nextDate = today
        }

        // Determine workout type (A or B alternating)
        let workoutType: String
        if let lastType = lastWorkoutType {
            workoutType = lastType == "A" ? "B" : "A"
        } else {
            workoutType = "A"
        }

        self.nextWorkoutDate = nextDate
        self.nextWorkoutType = workoutType

        // Schedule notification if enabled
        if notificationsEnabled {
            scheduleWorkoutNotification(for: nextDate, workoutType: workoutType, profile: profile)
        }

        saveSettings()
    }

    // MARK: - Notifications

    func scheduleWorkoutNotification(for date: Date, workoutType: String, profile: Int) {
        // Remove existing notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["workout_reminder_\(profile)"])

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDay = calendar.startOfDay(for: date)

        // Don't schedule notification for past dates
        guard workoutDay >= today else { return }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Train! 💪"
        content.body = "Workout \(workoutType) is scheduled for today. Let's crush it!"
        content.sound = .default
        content.badge = 1

        // Create trigger for the workout day at preferred time
        var triggerComponents = calendar.dateComponents([.year, .month, .day], from: date)
        triggerComponents.hour = preferredWorkoutTime.hour
        triggerComponents.minute = preferredWorkoutTime.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "workout_reminder_\(profile)",
            content: content,
            trigger: trigger
        )

        // Schedule
        notificationCenter.add(request) { _ in }
    }

    func cancelAllNotifications(for profile: Int) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["workout_reminder_\(profile)"])
    }

    // MARK: - Persistence

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "workoutNotificationsEnabled")
        UserDefaults.standard.set(preferredWorkoutTime.hour, forKey: "preferredWorkoutHour")
        UserDefaults.standard.set(preferredWorkoutTime.minute, forKey: "preferredWorkoutMinute")

        if let nextDate = nextWorkoutDate {
            UserDefaults.standard.set(nextDate, forKey: "nextWorkoutDate")
        }
        UserDefaults.standard.set(nextWorkoutType, forKey: "nextWorkoutType")
    }

    private func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "workoutNotificationsEnabled")

        let hour = UserDefaults.standard.integer(forKey: "preferredWorkoutHour")
        let minute = UserDefaults.standard.integer(forKey: "preferredWorkoutMinute")
        if hour > 0 {
            preferredWorkoutTime.hour = hour
            preferredWorkoutTime.minute = minute
        }

        if let savedDate = UserDefaults.standard.object(forKey: "nextWorkoutDate") as? Date {
            nextWorkoutDate = savedDate
        }
        if let savedType = UserDefaults.standard.string(forKey: "nextWorkoutType") {
            nextWorkoutType = savedType
        }
    }

    // MARK: - Manual Scheduling

    /// Manually set the next workout date (for rescheduling)
    func setNextWorkoutDate(_ date: Date, workoutType: String? = nil, profile: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)

        // Don't allow setting dates in the past
        guard selectedDay >= today else { return }

        nextWorkoutDate = selectedDay
        if let type = workoutType {
            nextWorkoutType = type
        }

        // Reschedule notification
        if notificationsEnabled {
            scheduleWorkoutNotification(for: selectedDay, workoutType: nextWorkoutType, profile: profile)
        }

        saveSettings()
    }

    /// Skip today's workout and reschedule to a new date
    func rescheduleWorkout(to newDate: Date, profile: Int) {
        setNextWorkoutDate(newDate, profile: profile)
    }

    // MARK: - Helper Methods

    func formattedNextWorkoutDate() -> String {
        guard let date = nextWorkoutDate else { return "Not scheduled" }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDay = calendar.startOfDay(for: date)

        if calendar.isDate(workoutDay, inSameDayAs: today) {
            return "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  calendar.isDate(workoutDay, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    func daysUntilNextWorkout() -> Int {
        guard let date = nextWorkoutDate else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDay = calendar.startOfDay(for: date)

        return calendar.dateComponents([.day], from: today, to: workoutDay).day ?? 0
    }
}
