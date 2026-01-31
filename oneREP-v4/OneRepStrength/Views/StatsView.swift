//
//  StatsView.swift
//  OneRepStrength v4
//
//  Redesigned stats view with streak flame and PR badges based on mockups (pages 17, 26)
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    var onBack: (() -> Void)? = nil

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var currentStreak: Int {
        calculateStreak()
    }

    private var weeklyWorkouts: [Int] {
        calculateWeeklyWorkouts()
    }

    private var personalRecords: [(exercise: String, weight: Double, date: Date)] {
        getPersonalRecords()
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
                    VStack(spacing: 20) {
                        // Streak Card
                        streakCard
                            .padding(.horizontal, 20)

                        // Charts Row
                        HStack(spacing: 12) {
                            weeklyWorkoutsCard
                            weightProgressCard
                        }
                        .padding(.horizontal, 20)

                        // PR Badges
                        prBadgesSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
            }

            // Floating Action Button - positioned above the menu dial
            VStack {
                Spacer()
                floatingActionButton
                    .padding(.bottom, 110)
            }
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

            Text("Stats")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 20) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Day Streak")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }

                if currentStreak > 0 {
                    Text(streakMessage)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.primary)
                }
            }

            Spacer()
        }
        .padding(24)
        .background {
            GlassBackground(isActive: currentStreak > 0, tintColor: .orange, cornerRadius: 20)
        }
        .shadow(color: .orange.opacity(themeManager.glassShadowOpacity * 0.4), radius: 12, y: 6)
    }

    private var streakMessage: String {
        switch currentStreak {
        case 1...3: return "Great start!"
        case 4...6: return "Keep it up!"
        case 7...13: return "You're on fire!"
        case 14...29: return "Unstoppable!"
        case 30...: return "Legend status!"
        default: return ""
        }
    }

    // MARK: - Weekly Workouts Card
    private var weeklyWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Workouts")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            // Bar chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let count = index < weeklyWorkouts.count ? weeklyWorkouts[index] : 0
                    let maxCount = max(weeklyWorkouts.max() ?? 1, 1)
                    let height = CGFloat(count) / CGFloat(maxCount) * 80

                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(count > 0 ? themeManager.primary : Color.gray.opacity(0.3))
                            .frame(width: 16, height: max(height, 4))

                        // Day label
                        Text(dayLabel(index))
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    private func dayLabel(_ index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index % 7]
    }

    // MARK: - Weight Progress Card
    private var weightProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Progress")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            // Simple line chart
            GeometryReader { geometry in
                let points = getProgressPoints()
                if points.count > 1 {
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height - 20
                        let maxWeight = points.map { $0.1 }.max() ?? 1
                        let minWeight = points.map { $0.1 }.min() ?? 0
                        let range = max(maxWeight - minWeight, 1)

                        for (index, point) in points.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                            let y = height - (CGFloat(point.1 - minWeight) / CGFloat(range) * height)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.primary.opacity(0.6), themeManager.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )

                    // Data points
                    ForEach(0..<points.count, id: \.self) { index in
                        let width = geometry.size.width
                        let height = geometry.size.height - 20
                        let maxWeight = points.map { $0.1 }.max() ?? 1
                        let minWeight = points.map { $0.1 }.min() ?? 0
                        let range = max(maxWeight - minWeight, 1)

                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let y = height - (CGFloat(points[index].1 - minWeight) / CGFloat(range) * height)

                        Circle()
                            .fill(themeManager.primary)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                } else {
                    Text("Not enough data")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - PR Badges Section
    private var prBadgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PR Badges")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            if personalRecords.isEmpty {
                Text("Complete workouts to earn PR badges")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                // Horizontal scroll of hexagon badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(personalRecords.prefix(6), id: \.exercise) { pr in
                            prBadge(exercise: pr.exercise, weight: pr.weight, date: pr.date)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 10, y: 5)
    }

    // MARK: - PR Badge (Hexagon)
    private func prBadge(exercise: String, weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            // Hexagon badge
            ZStack {
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2A2A30"), Color(hex: "1A1A1F")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 90)

                HexagonShape()
                    .stroke(themeManager.primary, lineWidth: 2)
                    .frame(width: 80, height: 90)

                // Exercise icon
                Image(systemName: exerciseIcon(for: exercise))
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.primary)
            }

            // Exercise name
            Text(shortName(exercise))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Weight
            Text("\(Int(weight)) lbs")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeManager.primary)

            // Date
            Text(formatDate(date))
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(width: 90)
    }

    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button(action: {
            // Export or share stats
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(themeManager.primary)
                        .shadow(color: themeManager.primary.opacity(0.5), radius: 15, y: 5)
                )
        }
    }

    // MARK: - Helper Functions
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        let workoutDates = Set(profileLogs.map { calendar.startOfDay(for: $0.date) })

        while workoutDates.contains(currentDate) || (streak == 0 && workoutDates.contains(calendar.date(byAdding: .day, value: -1, to: currentDate)!)) {
            if workoutDates.contains(currentDate) {
                streak += 1
            }
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }

    private func calculateWeeklyWorkouts() -> [Int] {
        let calendar = Calendar.current
        var counts = Array(repeating: 0, count: 7)

        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return counts
        }

        for log in profileLogs {
            let daysSinceWeekStart = calendar.dateComponents([.day], from: weekStart, to: log.date).day ?? 0
            if daysSinceWeekStart >= 0 && daysSinceWeekStart < 7 {
                counts[daysSinceWeekStart] += 1
            }
        }

        return counts
    }

    private func getPersonalRecords() -> [(exercise: String, weight: Double, date: Date)] {
        var records: [String: (weight: Double, date: Date)] = [:]

        for log in profileLogs {
            if let existing = records[log.exerciseName] {
                if log.weight > existing.weight {
                    records[log.exerciseName] = (log.weight, log.date)
                }
            } else {
                records[log.exerciseName] = (log.weight, log.date)
            }
        }

        return records.map { (exercise: $0.key, weight: $0.value.weight, date: $0.value.date) }
            .sorted { $0.weight > $1.weight }
    }

    private func getProgressPoints() -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: profileLogs) { log in
            calendar.startOfDay(for: log.date)
        }

        return grouped.map { (date, logs) in
            let maxWeight = logs.map { $0.weight }.max() ?? 0
            return (date, maxWeight)
        }
        .sorted { $0.0 < $1.0 }
        .suffix(10)
        .map { $0 }
    }

    private func exerciseIcon(for exercise: String) -> String {
        let name = exercise.lowercased()
        if name.contains("bench") || name.contains("press") && name.contains("chest") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("squat") {
            return "figure.strengthtraining.functional"
        } else if name.contains("deadlift") {
            return "figure.cross.training"
        } else if name.contains("row") || name.contains("pull") {
            return "figure.rowing"
        } else if name.contains("curl") {
            return "dumbbell.fill"
        } else {
            return "dumbbell.fill"
        }
    }

    private func shortName(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count > 2 {
            return String(words.prefix(2).joined(separator: " "))
        }
        return name
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2

        // Pointy-top hexagon
        let radius = min(width, height) / 2
        let angles: [Double] = [0, 60, 120, 180, 240, 300].map { $0 - 90 }

        for (index, angle) in angles.enumerated() {
            let radian = angle * .pi / 180
            let x = centerX + radius * CGFloat(cos(radian))
            let y = centerY + radius * CGFloat(sin(radian))

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        return path
    }
}

#Preview {
    StatsView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
