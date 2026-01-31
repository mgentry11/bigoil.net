
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
    @State private var workoutHistory: [WorkoutRecord] = []
    @State private var exerciseLog: [String: [ExerciseLogEntry]] = [:]
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingClearAlert = false
    @State private var showingDataAnalytics = false

    // User profile data
    @State private var userProfile: UserProfile = .defaultProfile
    @State private var isEditingProfile = false

    // Live data from WorkoutLogManager
    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var liveTotalSets: Int {
        logManager.getTotalSets(for: workoutManager.currentProfile)
    }

    private var liveTodaySets: Int {
        logManager.getTotalSetsToday(for: workoutManager.currentProfile)
    }

    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case workoutA = "A"
        case workoutB = "B"
    }

    var body: some View {
        VStack(spacing: 0) {
            // V3 Header
            HStack {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
                
                Button(action: { isEditingProfile = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header with User Info
                    VStack(spacing: 16) {
                        // Avatar and Name
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ThemeManager.shared.primary)
                                    .frame(width: 70, height: 70)

                                Text(userProfile.name.isEmpty ? "P\(workoutManager.currentProfile)" : String(userProfile.name.prefix(2)).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if userProfile.name.isEmpty {
                                    Text("Profile \(workoutManager.currentProfile)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(ThemeManager.shared.text)
                                } else {
                                    Text(userProfile.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(ThemeManager.shared.text)
                                }

                                Text("Member since \(userProfile.signupDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(.horizontal)

                        // User Stats Row
                        HStack(spacing: 0) {
                            ProfileInfoItem(label: "Age", value: "\(userProfile.age)")
                            Divider().frame(height: 30).background(Color.gray.opacity(0.5))
                            ProfileInfoItem(label: "Weight", value: "\(Int(userProfile.bodyWeight)) lbs")
                            Divider().frame(height: 30).background(Color.gray.opacity(0.5))
                            ProfileInfoItem(label: "Level", value: userProfile.experienceLevel.rawValue, color: userProfile.experienceLevel.color)
                        }
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Recommended Routine Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: userProfile.experienceLevel.icon)
                                    .foregroundColor(userProfile.experienceLevel.color)
                                Text("Recommended Routine")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ThemeManager.shared.text)
                            }

                            Text(userProfile.experienceLevel.recommendedRoutine)
                                .font(.callout)
                                .foregroundColor(ThemeManager.shared.primary)

                            Text(userProfile.experienceLevel.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(ThemeManager.shared.card)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.top, 10) // Reduced top padding since header is outside

                    // Stats Cards - matching web app
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Total Workouts", value: "\(totalWorkouts)", icon: "flame.fill")
                        StatCard(title: "This Week", value: "\(workoutsThisWeek)", icon: "calendar")
                        StatCard(title: "Current Streak", value: "\(currentStreak) days", icon: "bolt.fill")
                        StatCard(title: "Personal Records", value: "\(personalRecordCount)", icon: "trophy.fill")
                    }
                    .padding(.horizontal)

                    // Additional Stats Row
                    HStack(spacing: 16) {
                        MiniStatCard(title: "Total Exercises", value: "\(totalExercises)", color: ThemeManager.shared.primary)
                        MiniStatCard(title: "Total Weight", value: formatWeight(totalWeightLifted), color: .green)
                        MiniStatCard(title: "Avg Duration", value: formatDuration(averageWorkoutDuration), color: .blue)
                    }
                    .padding(.horizontal)

                    // Data Analytics Button
                    Button(action: { showingDataAnalytics = true }) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title3)
                                .foregroundColor(ThemeManager.shared.primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Data Analytics")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(ThemeManager.shared.text)
                                Text("Detailed exercise breakdowns & progress")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(ThemeManager.shared.card)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Workout History Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Workout History")
                                .font(.headline)
                                .foregroundColor(ThemeManager.shared.text)

                            Spacer()

                            // Filter buttons
                            HStack(spacing: 8) {
                                ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                                    FilterButton(
                                        title: filter.rawValue,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        if filteredHistory.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No workouts yet")
                                    .foregroundColor(.gray)
                                Text("Complete a workout to see your history")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(filteredHistory.prefix(10)) { record in
                                DetailedWorkoutCard(record: record, exerciseLog: exerciseLog)
                            }
                        }
                    }



                    // Clear Progress Button
                    if !workoutHistory.isEmpty {
                        Button(action: { showingClearAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Progress")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ThemeManager.shared.card)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 120) // Floating menu spacing
                }
            }
        }
        .background(ThemeManager.shared.background)
        .alert("Clear All Progress?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllProgress()
            }
        } message: {
            Text("This will delete all workout history and exercise data. This cannot be undone.")
        }
        .onAppear {
            loadUserProfile()
            loadWorkoutHistory()
            loadExerciseLog()
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileSheet(userProfile: $userProfile) {
                saveUserProfile()
            }
        }
        .sheet(isPresented: $showingDataAnalytics) {
            DataAnalyticsView()
        }
    }

    // MARK: - Filtered History

    var filteredHistory: [WorkoutRecord] {
        switch selectedFilter {
        case .all:
            return workoutHistory
        case .workoutA:
            return workoutHistory.filter { $0.workoutType == "A" }
        case .workoutB:
            return workoutHistory.filter { $0.workoutType == "B" }
        }
    }

    // MARK: - Computed Stats (Live from WorkoutLogManager)

    var totalWorkouts: Int {
        // Count unique workout days from live logs
        let calendar = Calendar.current
        let uniqueDays = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let uniqueDays = Set(profileLogs.filter { $0.date >= weekAgo }.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var currentStreak: Int {
        guard !profileLogs.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            let dayLogs = profileLogs.filter {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if !dayLogs.isEmpty {
                streak += 1
            } else if streak > 0 {
                break
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }

    var totalExercises: Int {
        // Total sets logged
        profileLogs.count
    }

    var personalRecordCount: Int {
        // Group logs by exercise name and count PRs
        let grouped = Dictionary(grouping: profileLogs) { $0.exerciseName }
        var prCount = 0
        for (_, logs) in grouped {
            let sortedLogs = logs.sorted { $0.date < $1.date }
            var currentMax: Double = 0
            for log in sortedLogs {
                if log.weight > currentMax {
                    currentMax = log.weight
                    prCount += 1
                }
            }
        }
        return prCount
    }

    var totalWeightLifted: Double {
        profileLogs.reduce(0) { $0 + $1.weight }
    }

    var averageWorkoutDuration: TimeInterval {
        // Not tracked in current log system, return 0
        return 0
    }

    // MARK: - Data Loading

    func loadUserProfile() {
        let key = "userProfile_P\(workoutManager.currentProfile)"
        if let data = UserDefaults.standard.data(forKey: key),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        } else {
            // New profile - set signup date to now
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

    func loadWorkoutHistory() {
        if let data = UserDefaults.standard.data(forKey: "workoutHistory_P\(workoutManager.currentProfile)"),
           let history = try? JSONDecoder().decode([WorkoutRecord].self, from: data) {
            workoutHistory = history.sorted { $0.date > $1.date }
        }
    }

    func loadExerciseLog() {
        if let data = UserDefaults.standard.data(forKey: "exerciseLog_P\(workoutManager.currentProfile)"),
           let log = try? JSONDecoder().decode([String: [ExerciseLogEntry]].self, from: data) {
            exerciseLog = log
        }
    }

    func clearAllProgress() {
        UserDefaults.standard.removeObject(forKey: "workoutHistory_P\(workoutManager.currentProfile)")
        UserDefaults.standard.removeObject(forKey: "exerciseLog_P\(workoutManager.currentProfile)")
        workoutHistory = []
        exerciseLog = [:]
    }

    // MARK: - Helpers

    func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.1fK", weight / 1000)
        }
        return "\(Int(weight)) lbs"
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }

    func getPersonalRecord(for exerciseName: String) -> Double? {
        exerciseLog[exerciseName]?.map { $0.weight }.max()
    }
}

// MARK: - Subviews

struct ProfileInfoItem: View {
    let label: String
    let value: String
    var color: Color? = nil

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color ?? ThemeManager.shared.text)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Log Entry Model

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

// MARK: - Workout Record Model

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

// MARK: - Filter Button

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ThemeManager.shared.card)
        .cornerRadius(10)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ThemeManager.shared.primary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(12)
    }
}

// MARK: - Detailed Workout Card (shows exercises)

struct DetailedWorkoutCard: View {
    let record: WorkoutRecord
    let exerciseLog: [String: [ExerciseLogEntry]]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header - always visible
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Workout \(record.workoutType)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ThemeManager.shared.text)

                            if hasAnyPR {
                                Text("PR")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ThemeManager.shared.primary)
                                    .cornerRadius(4)
                            }
                        }

                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(record.exerciseCount) exercises")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.primary)

                        Text(formatDuration(record.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                .padding()
            }

            // Expanded exercise list
            if isExpanded && !record.exercises.isEmpty {
                VStack(spacing: 8) {
                    ForEach(record.exercises) { exercise in
                        ExerciseDetailRow(
                            exercise: exercise,
                            isPR: isPersonalRecord(exercise: exercise)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(ThemeManager.shared.card)
        .cornerRadius(10)
        .padding(.horizontal)
    }

    var hasAnyPR: Bool {
        record.exercises.contains { isPersonalRecord(exercise: $0) }
    }

    func isPersonalRecord(exercise: ExerciseRecordData) -> Bool {
        guard let entries = exerciseLog[exercise.name] else { return false }
        guard let maxWeight = entries.map({ $0.weight }).max() else { return false }
        return exercise.weight >= maxWeight && exercise.weight > 0
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Detail Row

struct ExerciseDetailRow: View {
    let exercise: ExerciseRecordData
    let isPR: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.text)

                if exercise.duration > 0 {
                    Text(formatDuration(exercise.duration))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(Int(exercise.weight)) lbs")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ThemeManager.shared.primary)

                if exercise.reachedFailure {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                if isPR {
                    Text("PR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(ThemeManager.shared.card)
        .cornerRadius(6)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}



// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    let onSave: () -> Void

    @State private var nameText: String = ""
    @State private var ageText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        TextField("Enter your name", text: $nameText)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Age")
                            .foregroundColor(.gray)
                        TextField("Age", text: $ageText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Body Weight (lbs)")
                            .foregroundColor(.gray)
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Experience Level") {
                    ForEach(UserProfile.ExperienceLevel.allCases, id: \.self) { level in
                        Button(action: {
                            userProfile.experienceLevel = level
                        }) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(level.color)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(ThemeManager.shared.text)
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                if userProfile.experienceLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                            }
                        }
                    }
                }

                Section("Member Since") {
                    Text(userProfile.signupDate.formatted(date: .long, time: .omitted))
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
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

#Preview {
    ProfileView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.light)
}
