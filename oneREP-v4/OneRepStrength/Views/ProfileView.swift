//
//  ProfileView.swift
//  OneRepStrength v4
//
//  Redesigned profile view with achievements based on mockups (pages 14, 23)
//

import SwiftUI

// MARK: - User Profile Model

struct UserProfile: Codable {
    var name: String
    var age: Int
    var bodyWeight: Double
    var signupDate: Date
    var experienceLevel: ExperienceLevel

    enum ExperienceLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var description: String {
            switch self {
            case .beginner:
                return "New to HIT training (0-6 months)"
            case .intermediate:
                return "Some HIT experience (6-24 months)"
            case .advanced:
                return "Experienced HIT practitioner (2+ years)"
            }
        }

        var recommendedRoutine: String {
            switch self {
            case .beginner:
                return "2x per week, Workout A only"
            case .intermediate:
                return "2x per week, alternating A/B"
            case .advanced:
                return "3x per week, A/B/A then B/A/B"
            }
        }

        var icon: String {
            switch self {
            case .beginner: return "leaf.fill"
            case .intermediate: return "flame.fill"
            case .advanced: return "bolt.fill"
            }
        }

        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }

    static var defaultProfile: UserProfile {
        UserProfile(
            name: "",
            age: 30,
            bodyWeight: 150,
            signupDate: Date(),
            experienceLevel: .beginner
        )
    }
}

struct ProfileView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    var onBack: (() -> Void)? = nil

    @State private var userProfile: UserProfile = .defaultProfile
    @State private var isEditingProfile = false
    @State private var showingDataAnalytics = false

    // Live data from WorkoutLogManager
    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Avatar and Name
                        profileHeader
                            .padding(.horizontal, 20)

                        // Stats Cards
                        statsSection
                            .padding(.horizontal, 20)

                        // Achievements Section
                        achievementsSection
                            .padding(.horizontal, 20)

                        // Experience Level Card
                        experienceLevelCard
                            .padding(.horizontal, 20)

                        // Data Analytics Button
                        dataAnalyticsButton
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
            }

            // Floating Edit Profile Button - positioned above the menu dial
            VStack {
                Spacer()
                floatingEditButton
                    .padding(.bottom, 110)
            }
        }
        .onAppear {
            loadUserProfile()
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileSheetV4(userProfile: $userProfile) {
                saveUserProfile()
            }
        }
        .sheet(isPresented: $showingDataAnalytics) {
            DataAnalyticsView()
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { if let onBack { onBack() } else { dismiss() } }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Profile Header (Avatar + Name)
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with orange ring
            ZStack {
                // Outer orange ring
                Circle()
                    .stroke(themeManager.primary, lineWidth: 4)
                    .frame(width: 100, height: 100)

                // Dark inner circle
                Circle()
                    .fill(Color(hex: "1A1A1F"))
                    .frame(width: 90, height: 90)

                // Initial letter
                Text(avatarInitial)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(themeManager.primary)
            }

            // Name
            Text(displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Member since
            Text("Member since \(memberSinceText)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
    }

    private var avatarInitial: String {
        if userProfile.name.isEmpty {
            return "P\(workoutManager.currentProfile)"
        }
        return String(userProfile.name.prefix(1)).uppercased()
    }

    private var displayName: String {
        if userProfile.name.isEmpty {
            return "Profile \(workoutManager.currentProfile)"
        }
        return userProfile.name
    }

    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: userProfile.signupDate)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            ProfileStatCard(
                value: "\(totalWorkouts)",
                label: "Total Workouts",
                icon: "flame.fill"
            )

            ProfileStatCard(
                value: "\(currentStreak)",
                label: "Day Streak",
                icon: "bolt.fill"
            )

            ProfileStatCard(
                value: formatTotalTime(totalWorkoutTime),
                label: "Total Time",
                icon: "clock.fill"
            )
        }
    }

    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(achievements, id: \.title) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1A1F"))
        )
    }

    private var achievements: [Achievement] {
        var list: [Achievement] = []

        // Workout count achievements
        if totalWorkouts >= 100 {
            list.append(Achievement(title: "Century", subtitle: "100 Workouts", icon: "star.fill", isEarned: true))
        } else if totalWorkouts >= 50 {
            list.append(Achievement(title: "Dedicated", subtitle: "50 Workouts", icon: "star.fill", isEarned: true))
        } else if totalWorkouts >= 10 {
            list.append(Achievement(title: "Getting Started", subtitle: "10 Workouts", icon: "star.fill", isEarned: true))
        } else {
            list.append(Achievement(title: "First Steps", subtitle: "10 Workouts", icon: "star", isEarned: false, progress: Double(totalWorkouts) / 10.0))
        }

        // Streak achievements
        if currentStreak >= 30 {
            list.append(Achievement(title: "On Fire", subtitle: "30-Day Streak", icon: "flame.fill", isEarned: true))
        } else if currentStreak >= 7 {
            list.append(Achievement(title: "Consistent", subtitle: "7-Day Streak", icon: "flame.fill", isEarned: true))
        } else {
            list.append(Achievement(title: "Building Habit", subtitle: "7-Day Streak", icon: "flame", isEarned: false, progress: Double(currentStreak) / 7.0))
        }

        // Weight achievements
        let maxWeight = profileLogs.map { $0.weight }.max() ?? 0
        if maxWeight >= 300 {
            list.append(Achievement(title: "Power Lifter", subtitle: "300+ lbs PR", icon: "trophy.fill", isEarned: true))
        } else if maxWeight >= 200 {
            list.append(Achievement(title: "Strong", subtitle: "200+ lbs PR", icon: "trophy.fill", isEarned: true))
        } else if maxWeight >= 100 {
            list.append(Achievement(title: "Rising", subtitle: "100+ lbs PR", icon: "trophy.fill", isEarned: true))
        } else {
            list.append(Achievement(title: "Beginner", subtitle: "100+ lbs PR", icon: "trophy", isEarned: false, progress: maxWeight / 100.0))
        }

        // Experience level achievement
        list.append(Achievement(
            title: userProfile.experienceLevel.rawValue,
            subtitle: "Experience",
            icon: userProfile.experienceLevel.icon,
            isEarned: true,
            color: userProfile.experienceLevel.color
        ))

        return list
    }

    // MARK: - Experience Level Card
    private var experienceLevelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: userProfile.experienceLevel.icon)
                    .font(.system(size: 20))
                    .foregroundColor(userProfile.experienceLevel.color)

                Text("Experience Level")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(userProfile.experienceLevel.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.primary.opacity(0.2))
                    .cornerRadius(8)
            }

            Text(userProfile.experienceLevel.recommendedRoutine)
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text(userProfile.experienceLevel.description)
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1F"))
        )
    }

    // MARK: - Data Analytics Button
    private var dataAnalyticsButton: some View {
        Button(action: { showingDataAnalytics = true }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.primary.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Analytics")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("View detailed exercise breakdowns")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1A1F"))
            )
        }
    }

    // MARK: - Floating Edit Button
    private var floatingEditButton: some View {
        Button(action: { isEditingProfile = true }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .bold))
                Text("Edit Profile")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(themeManager.primary)
                    .shadow(color: themeManager.primary.opacity(0.5), radius: 15, y: 5)
            )
        }
    }

    // MARK: - Computed Stats

    var totalWorkouts: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var currentStreak: Int {
        guard !profileLogs.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let workoutDates = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })

        // Check if worked out today or yesterday to start counting
        if !workoutDates.contains(checkDate) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
               workoutDates.contains(yesterday) {
                checkDate = yesterday
            } else {
                return 0
            }
        }

        while workoutDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    var totalWorkoutTime: TimeInterval {
        // Estimate: ~2 min per set
        return TimeInterval(profileLogs.count * 120)
    }

    func formatTotalTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours >= 1 {
            return "\(hours)h"
        }
        let minutes = Int(seconds) / 60
        return "\(minutes)m"
    }

    // MARK: - Data Loading

    func loadUserProfile() {
        let key = "userProfile_P\(workoutManager.currentProfile)"
        if let data = UserDefaults.standard.data(forKey: key),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        } else {
            userProfile = .defaultProfile
            userProfile.signupDate = Date()
        }
    }

    func saveUserProfile() {
        let key = "userProfile_P\(workoutManager.currentProfile)"
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Profile Stat Card

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(themeManager.primary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1F"))
        )
    }
}

// MARK: - Achievement Model

struct Achievement {
    let title: String
    let subtitle: String
    let icon: String
    var isEarned: Bool
    var progress: Double = 1.0
    var color: Color? = nil
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    @ObservedObject var themeManager = ThemeManager.shared

    private var badgeColor: Color {
        achievement.color ?? themeManager.primary
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer circle (progress or filled)
                Circle()
                    .stroke(
                        achievement.isEarned ? badgeColor : Color.gray.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 70, height: 70)

                // Progress indicator for unearned
                if !achievement.isEarned && achievement.progress > 0 {
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(badgeColor.opacity(0.5), lineWidth: 3)
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }

                // Inner circle
                Circle()
                    .fill(achievement.isEarned ? badgeColor.opacity(0.2) : Color(hex: "1A1A1F"))
                    .frame(width: 60, height: 60)

                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isEarned ? badgeColor : .gray)
            }

            Text(achievement.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(achievement.isEarned ? .white : .gray)

            Text(achievement.subtitle)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(width: 90)
    }
}

// MARK: - Edit Profile Sheet V4

struct EditProfileSheetV4: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    let onSave: () -> Void

    @State private var nameText: String = ""
    @State private var ageText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        ZStack {
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)

                    Spacer()

                    Text("Edit Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Save") {
                        saveChanges()
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(themeManager.primary)
                    .fontWeight(.semibold)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        // Personal Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            ProfileTextField(label: "Name", text: $nameText, placeholder: "Enter your name")
                            ProfileTextField(label: "Age", text: $ageText, placeholder: "Age", keyboardType: .numberPad)
                            ProfileTextField(label: "Weight (lbs)", text: $weightText, placeholder: "Body weight", keyboardType: .decimalPad)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1A1A1F"))
                        )

                        // Experience Level
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Experience Level")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            ForEach(UserProfile.ExperienceLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    userProfile.experienceLevel = level
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: level.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(level.color)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(level.rawValue)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            Text(level.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        if userProfile.experienceLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeManager.primary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1A1A1F"))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            nameText = userProfile.name
            ageText = "\(userProfile.age)"
            weightText = "\(Int(userProfile.bodyWeight))"
        }
    }

    func saveChanges() {
        userProfile.name = nameText.trimmingCharacters(in: .whitespaces)
        if let age = Int(ageText), age > 0 && age < 120 {
            userProfile.age = age
        }
        if let weight = Double(weightText), weight > 0 {
            userProfile.bodyWeight = weight
        }
    }
}

// MARK: - Profile Text Field

struct ProfileTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Legacy Models (kept for compatibility)

struct ExerciseLogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double
    let reachedFailure: Bool
    let duration: TimeInterval

    init(id: UUID = UUID(), date: Date = Date(), weight: Double, reachedFailure: Bool, duration: TimeInterval = 0) {
        self.id = id
        self.date = date
        self.weight = weight
        self.reachedFailure = reachedFailure
        self.duration = duration
    }
}

struct WorkoutRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let workoutType: String
    let exerciseCount: Int
    let duration: TimeInterval
    var exercises: [ExerciseRecordData]

    init(id: UUID = UUID(), date: Date = Date(), workoutType: String, exerciseCount: Int, duration: TimeInterval, exercises: [ExerciseRecordData] = []) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.exerciseCount = exerciseCount
        self.duration = duration
        self.exercises = exercises
    }
}

struct ExerciseRecordData: Codable, Identifiable {
    let id: UUID
    let name: String
    let weight: Double
    let reachedFailure: Bool
    let duration: TimeInterval

    init(id: UUID = UUID(), name: String, weight: Double, reachedFailure: Bool, duration: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.weight = weight
        self.reachedFailure = reachedFailure
        self.duration = duration
    }
}

#Preview {
    ProfileView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
