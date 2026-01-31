//
//  DataAnalyticsView.swift
//  HITCoachPro
//
//  Detailed data analytics view for fine-grained workout data analysis
//

import SwiftUI

struct DataAnalyticsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var selectedExercise: String?
    @State private var selectedTimeRange: TimeRange = .all
    @State private var showSummary = false
    @State private var showRecords = true
    @State private var showBreakdown = false

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        case all = "All Time"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .all: return nil
            }
        }
    }

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var filteredLogs: [WorkoutLogEntry] {
        guard let days = selectedTimeRange.days else { return profileLogs }
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return profileLogs.filter { $0.date >= startDate }
    }

    private var uniqueExercises: [String] {
        Array(Set(profileLogs.map { $0.exerciseName })).sorted()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    keyMetricCard
                        .padding(.horizontal)
                        .padding(.top)
                    
                    timeRangeSelector
                        .padding(.horizontal)

                    CollapsibleSection(title: "Summary Stats", icon: "chart.bar.fill", isExpanded: $showSummary) {
                        summaryStatsSection
                    }
                    .padding(.horizontal)

                    CollapsibleSection(title: "Personal Records", icon: "trophy.fill", isExpanded: $showRecords) {
                        personalRecordsScrollView
                    }

                    CollapsibleSection(title: "Exercise Breakdown", icon: "list.bullet", isExpanded: $showBreakdown) {
                        exerciseBreakdownContent
                    }
                    .padding(.horizontal)

                    if selectedExercise != nil {
                        exerciseDetailSection
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(ThemeManager.shared.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private var keyMetricCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(weeklySetCount) Sets")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeManager.shared.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Volume")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatVolume(weeklyVolume))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(16)
    }
    
    private var weeklySetCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return profileLogs.filter { $0.date >= startOfWeek }.count
    }
    
    private var weeklyVolume: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return profileLogs.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.weight }
    }
    
    private var personalRecordsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(getPersonalRecords(), id: \.exercise) { pr in
                    PRCard(exercise: pr.exercise, weight: pr.weight, date: pr.date)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var exerciseBreakdownContent: some View {
        VStack(spacing: 8) {
            ForEach(uniqueExercises, id: \.self) { exercise in
                ExerciseBreakdownCard(
                    exercise: exercise,
                    logs: filteredLogs.filter { $0.exerciseName == exercise },
                    isSelected: selectedExercise == exercise,
                    onTap: {
                        withAnimation {
                            selectedExercise = selectedExercise == exercise ? nil : exercise
                        }
                    }
                )
            }
        }
    }

    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeRange == range ? .black : .gray)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTimeRange == range ? ThemeManager.shared.primary : Color(white: 0.15))
                            .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Summary Stats
    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsStat(
                    title: "Sets",
                    value: "\(filteredLogs.count)",
                    icon: "number",
                    color: ThemeManager.shared.primary
                )

                AnalyticsStat(
                    title: "Volume",
                    value: formatVolume(filteredLogs.reduce(0) { $0 + $1.weight }),
                    icon: "scalemass.fill",
                    color: .blue
                )

                AnalyticsStat(
                    title: "Exercises",
                    value: "\(Set(filteredLogs.map { $0.exerciseName }).count)",
                    icon: "list.bullet",
                    color: .green
                )

                AnalyticsStat(
                    title: "Workouts",
                    value: "\(uniqueWorkoutDays)",
                    icon: "calendar",
                    color: .purple
                )

                AnalyticsStat(
                    title: "Avg Weight",
                    value: "\(Int(averageWeight)) lbs",
                    icon: "chart.bar.fill",
                    color: .orange
                )

                AnalyticsStat(
                    title: "Failure %",
                    value: "\(Int(failurePercentage))%",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }

    private var uniqueWorkoutDays: Int {
        let calendar = Calendar.current
        return Set(filteredLogs.map { calendar.startOfDay(for: $0.date) }).count
    }

    private var averageWeight: Double {
        guard !filteredLogs.isEmpty else { return 0 }
        return filteredLogs.reduce(0) { $0 + $1.weight } / Double(filteredLogs.count)
    }

    private var failurePercentage: Double {
        guard !filteredLogs.isEmpty else { return 0 }
        let failureCount = filteredLogs.filter { $0.reachedFailure }.count
        return Double(failureCount) / Double(filteredLogs.count) * 100
    }

    // MARK: - Personal Records Section
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(ThemeManager.shared.primary)
                Text("Personal Records")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getPersonalRecords(), id: \.exercise) { pr in
                        PRCard(
                            exercise: pr.exercise,
                            weight: pr.weight,
                            date: pr.date
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Exercise Breakdown Section
    private var exerciseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercise Breakdown")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
                if selectedExercise != nil {
                    Button("Clear") {
                        selectedExercise = nil
                    }
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(uniqueExercises, id: \.self) { exercise in
                    ExerciseBreakdownCard(
                        exercise: exercise,
                        logs: filteredLogs.filter { $0.exerciseName == exercise },
                        isSelected: selectedExercise == exercise,
                        onTap: {
                            withAnimation {
                                selectedExercise = selectedExercise == exercise ? nil : exercise
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Exercise Detail Section
    @ViewBuilder
    private var exerciseDetailSection: some View {
        if let exercise = selectedExercise {
            let exerciseLogs = filteredLogs.filter { $0.exerciseName == exercise }.sorted { $0.date > $1.date }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(exercise) History")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)
                    Spacer()
                    Text("\(exerciseLogs.count) sets")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.primary)
                }
                .padding(.horizontal)

                // Progress mini-chart
                if exerciseLogs.count >= 2 {
                    WeightProgressChart(logs: exerciseLogs)
                        .padding(.horizontal)
                }

                // Detailed log list
                VStack(spacing: 6) {
                    ForEach(exerciseLogs) { log in
                        ExerciseLogDetailRow(log: log)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return "\(Int(volume))"
    }

    private func getPersonalRecords() -> [(exercise: String, weight: Double, date: Date)] {
        var records: [(exercise: String, weight: Double, date: Date)] = []

        for exercise in uniqueExercises {
            let exerciseLogs = profileLogs.filter { $0.exerciseName == exercise }
            if let maxLog = exerciseLogs.max(by: { $0.weight < $1.weight }) {
                records.append((exercise: exercise, weight: maxLog.weight, date: maxLog.date))
            }
        }

        return records.sorted { $0.weight > $1.weight }
    }
}

// MARK: - Analytics Stat
struct AnalyticsStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)

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

// MARK: - PR Card
struct PRCard: View {
    let exercise: String
    let weight: Double
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
                Spacer()
            }

            Text(exercise)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ThemeManager.shared.text)
                .lineLimit(1)

            Text("\(Int(weight)) lbs")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.primary)

            Text(formatDate(date))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 100)
        .padding(12)
        .background(ThemeManager.shared.card)
        .cornerRadius(10)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Exercise Breakdown Card
struct ExerciseBreakdownCard: View {
    let exercise: String
    let logs: [WorkoutLogEntry]
    let isSelected: Bool
    let onTap: () -> Void

    private var maxWeight: Double {
        logs.map { $0.weight }.max() ?? 0
    }

    private var avgWeight: Double {
        guard !logs.isEmpty else { return 0 }
        return logs.reduce(0) { $0 + $1.weight } / Double(logs.count)
    }

    private var failureRate: Double {
        guard !logs.isEmpty else { return 0 }
        let failureCount = logs.filter { $0.reachedFailure }.count
        return Double(failureCount) / Double(logs.count) * 100
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Exercise name
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ThemeManager.shared.text)
                        .lineLimit(1)

                    Text("\(logs.count) sets")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Stats
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(Int(maxWeight))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.primary)
                        Text("Max")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    VStack(spacing: 2) {
                        Text("\(Int(avgWeight))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ThemeManager.shared.text)
                        Text("Avg")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    VStack(spacing: 2) {
                        Text("\(Int(failureRate))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(failureRate > 70 ? .green : .gray)
                        Text("Fail")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(isSelected ? Color(white: 0.18) : Color(white: 0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? ThemeManager.shared.primary.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weight Progress Chart
struct WeightProgressChart: View {
    let logs: [WorkoutLogEntry]

    private var sortedLogs: [WorkoutLogEntry] {
        logs.sorted { $0.date < $1.date }
    }

    private var maxWeight: Double {
        logs.map { $0.weight }.max() ?? 100
    }

    private var minWeight: Double {
        logs.map { $0.weight }.min() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.caption)
                .foregroundColor(.gray)

            GeometryReader { geometry in
                let width = geometry.size.width
                let height: CGFloat = 80
                let range = max(maxWeight - minWeight, 10)

                ZStack(alignment: .bottomLeading) {
                    // Background grid
                    VStack(spacing: height / 4) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(Color(white: 0.2))
                                .frame(height: 1)
                        }
                    }
                    .frame(height: height)

                    // Line chart
                    Path { path in
                        guard sortedLogs.count >= 2 else { return }

                        let points = sortedLogs.enumerated().map { index, log -> CGPoint in
                            let x = CGFloat(index) / CGFloat(sortedLogs.count - 1) * width
                            let y = height - (CGFloat(log.weight - minWeight) / CGFloat(range) * height)
                            return CGPoint(x: x, y: y)
                        }

                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(ThemeManager.shared.primary, lineWidth: 2)

                    // Data points
                    ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, log in
                        let x = CGFloat(index) / CGFloat(max(sortedLogs.count - 1, 1)) * width
                        let y = height - (CGFloat(log.weight - minWeight) / CGFloat(range) * height)

                        Circle()
                            .fill(log.reachedFailure ? Color.green : ThemeManager.shared.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
                .frame(height: height)
            }
            .frame(height: 80)

            // Legend
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(ThemeManager.shared.primary)
                        .frame(width: 6, height: 6)
                    Text("Weight")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("\(Int(minWeight)) - \(Int(maxWeight)) lbs")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(10)
    }
}

// MARK: - Exercise Log Detail Row
struct ExerciseLogDetailRow: View {
    let log: WorkoutLogEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(log.date))
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.text)

                Text(formatTime(log.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(Int(log.weight)) lbs")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ThemeManager.shared.primary)

            if log.reachedFailure {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            if let rpe = log.rpe {
                Text("RPE \(rpe)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ThemeManager.shared.card)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(ThemeManager.shared.card)
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(ThemeManager.shared.primary)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(ThemeManager.shared.card)
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content()
                    .padding(.top, 12)
            }
        }
    }
}

#Preview {
    DataAnalyticsView()
        .environmentObject(WorkoutManager())
}
