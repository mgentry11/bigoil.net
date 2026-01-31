//
//  ProgressChartsView.swift
//  HITCoachPro
//
//  Displays progress charts and detailed statistics

import SwiftUI
import Charts

struct ProgressChartsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var selectedExercise: String?

    private var exercises: [String] {
        logManager.getUniqueExercises(for: workoutManager.currentProfile)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise Selector
                if !exercises.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(exercises, id: \.self) { exercise in
                                ExerciseChip(
                                    name: exercise,
                                    isSelected: selectedExercise == exercise
                                ) {
                                    selectedExercise = exercise
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if let exercise = selectedExercise {
                        // Progress Chart
                        ExerciseProgressChart(
                            exerciseName: exercise,
                            profile: workoutManager.currentProfile
                        )
                        .padding(.horizontal)

                        // Exercise Stats
                        ExerciseStatsCard(
                            exerciseName: exercise,
                            profile: workoutManager.currentProfile
                        )
                        .padding(.horizontal)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Data Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.text)

                        Text("Complete some workouts to see your progress charts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                }

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .onAppear {
            if selectedExercise == nil {
                selectedExercise = exercises.first
            }
        }
    }
}

// MARK: - Exercise Chip
struct ExerciseChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.2))
                .cornerRadius(20)
        }
    }
}

// MARK: - Exercise Progress Chart
struct ExerciseProgressChart: View {
    let exerciseName: String
    let profile: Int
    @ObservedObject var logManager = WorkoutLogManager.shared

    private var chartData: [(date: Date, weight: Double)] {
        logManager.getProgressData(for: exerciseName, profile: profile, last: 20)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Progress")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            if chartData.count >= 2 {
                Chart {
                    ForEach(chartData.indices, id: \.self) { index in
                        let data = chartData[index]
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Weight", data.weight)
                        )
                        .foregroundStyle(ThemeManager.shared.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Weight", data.weight)
                        )
                        .foregroundStyle(ThemeManager.shared.primary)

                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("Weight", data.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ThemeManager.shared.primary.opacity(0.3), ThemeManager.shared.primary.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight))")
                                    .foregroundColor(.gray)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.3))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .foregroundColor(.gray)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Need at least 2 data points")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(16)
    }
}

// MARK: - Exercise Stats Card
struct ExerciseStatsCard: View {
    let exerciseName: String
    let profile: Int
    @ObservedObject var logManager = WorkoutLogManager.shared

    private var maxWeight: Double? {
        logManager.getMaxWeight(for: exerciseName, profile: profile)
    }

    private var estimated1RM: Double? {
        logManager.getEstimated1RM(for: exerciseName, profile: profile)
    }

    private var averageRPE: Double? {
        logManager.getAverageRPE(for: exerciseName, profile: profile)
    }

    private var failureRate: Double {
        logManager.getFailureRate(for: exerciseName, profile: profile)
    }

    private var totalSets: Int {
        logManager.getLogs(for: exerciseName, profile: profile).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercise Statistics")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatItem(title: "Personal Record", value: maxWeight.map { "\(Int($0)) lbs" } ?? "-", icon: "trophy.fill", color: ThemeManager.shared.primary)
                StatItem(title: "Est. 1RM", value: estimated1RM.map { "\(Int($0)) lbs" } ?? "-", icon: "flame.fill", color: .orange)
                StatItem(title: "Total Sets", value: "\(totalSets)", icon: "number", color: .blue)
                StatItem(title: "Failure Rate", value: String(format: "%.0f%%", failureRate), icon: "bolt.fill", color: .green)

                if let rpe = averageRPE {
                    StatItem(title: "Avg RPE", value: String(format: "%.1f", rpe), icon: "heart.fill", color: .red)
                }
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
            }

            Spacer()
        }
        .padding(10)
        .background(ThemeManager.shared.card)
        .cornerRadius(10)
    }
}

// MARK: - 1RM Calculator View
struct OneRMCalculatorView: View {
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var calculated1RM: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("1RM Calculator")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("lbs", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(8)
                        .foregroundColor(ThemeManager.shared.text)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("1-12", text: $reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(8)
                        .foregroundColor(ThemeManager.shared.text)
                }

                Button(action: calculate1RM) {
                    Image(systemName: "equal.circle.fill")
                        .font(.title)
                        .foregroundColor(ThemeManager.shared.primary)
                }
                .padding(.top, 20)
            }

            if let result = calculated1RM {
                HStack {
                    Text("Estimated 1RM:")
                        .foregroundColor(.gray)
                    Text("\(Int(result)) lbs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.primary)
                }
                .padding(.top, 8)
            }

            // Percentage chart
            if let result = calculated1RM {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Percentages")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach([100, 95, 90, 85, 80, 75, 70], id: \.self) { percent in
                        HStack {
                            Text("\(percent)%")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 40, alignment: .trailing)
                            ProgressView(value: Double(percent) / 100)
                                .tint(ThemeManager.shared.primary)
                            Text("\(Int(result * Double(percent) / 100)) lbs")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeManager.shared.text)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(16)
    }

    private func calculate1RM() {
        guard let weightVal = Double(weight),
              let repsVal = Int(reps),
              weightVal > 0,
              repsVal > 0,
              repsVal <= 12 else {
            calculated1RM = nil
            return
        }

        if repsVal == 1 {
            calculated1RM = weightVal
        } else {
            // Brzycki formula
            calculated1RM = weightVal * (36.0 / (37.0 - Double(repsVal)))
        }
    }
}

// MARK: - Warm-up Calculator View
struct WarmupCalculatorView: View {
    @State private var workingWeight: String = ""
    @State private var warmupSets: [(percent: Int, weight: Int, reps: Int)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Warm-up Calculator")
                .font(.headline)
                .foregroundColor(ThemeManager.shared.text)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("lbs", text: $workingWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(8)
                        .foregroundColor(ThemeManager.shared.text)
                }

                Button(action: calculateWarmup) {
                    Text("Calculate")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeManager.shared.primary)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
            }

            if !warmupSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Warm-up")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach(warmupSets.indices, id: \.self) { index in
                        let set = warmupSets[index]
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 50, alignment: .leading)

                            Text("\(set.weight) lbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeManager.shared.text)

                            Text("(\(set.percent)%)")
                                .font(.caption)
                                .foregroundColor(ThemeManager.shared.primary)

                            Spacer()

                            Text("\(set.reps) reps")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(8)
                    }

                    HStack {
                        Text("Working Set")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.primary)
                            .frame(width: 80, alignment: .leading)

                        Text("\(workingWeight) lbs")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeManager.shared.primary)

                        Text("(100%)")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.primary)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(ThemeManager.shared.primary.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(ThemeManager.shared.card)
        .cornerRadius(16)
    }

    private func calculateWarmup() {
        guard let weight = Double(workingWeight), weight > 0 else {
            warmupSets = []
            return
        }

        // Standard warm-up protocol
        let percentages: [(percent: Int, reps: Int)] = [
            (40, 10),
            (55, 6),
            (70, 4),
            (85, 2)
        ]

        warmupSets = percentages.map { (percent, reps) in
            let warmupWeight = Int(weight * Double(percent) / 100)
            // Round to nearest 5
            let roundedWeight = (warmupWeight / 5) * 5
            return (percent: percent, weight: roundedWeight, reps: reps)
        }
    }
}

#Preview {
    ProgressChartsView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.light)
}
