//
//  RoutinesView.swift
//  HITCoachPro
//
//  Main view for browsing, managing, and loading workout routines/templates
//

import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var showingSaveSheet = false
    @State private var showingRoutineDetail: WorkoutTemplate?
    @State private var selectedTab: RoutinesTab = .saved

    enum RoutinesTab: String, CaseIterable {
        case saved = "Saved"
        case recent = "Recent"
    }

    private var savedTemplates: [WorkoutTemplate] {
        templateManager.getSavedTemplates(for: workoutManager.currentProfile)
    }

    private var recentWorkouts: [(date: Date, entries: [WorkoutLogEntry])] {
        templateManager.getRecentWorkoutsFromLog(for: workoutManager.currentProfile, limit: 10)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Routines")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Spacer()

                // Create New Template button
                Button(action: { showingSaveSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .padding()
            .background(ThemeManager.shared.card)

            // Quick Action: Repeat Last Workout
            if let lastWorkout = recentWorkouts.first {
                RepeatLastWorkoutCard(
                    date: lastWorkout.date,
                    exerciseCount: Set(lastWorkout.entries.map { $0.exerciseName }).count,
                    onRepeat: {
                        workoutManager.loadFromLogEntries(lastWorkout.entries)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 12)
            }

            // Tab Selector
            HStack(spacing: 8) {
                ForEach(RoutinesTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? .black : .gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? ThemeManager.shared.primary : Color(white: 0.15))
                            .cornerRadius(20)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Content
            ScrollView {
                switch selectedTab {
                case .saved:
                    savedTemplatesSection
                case .recent:
                    recentWorkoutsSection
                }
            }
        }
        .background(ThemeManager.shared.background)
        .sheet(isPresented: $showingSaveSheet) {
            SaveAsTemplateSheet(
                exercises: workoutManager.currentWorkout.exercises,
                profile: workoutManager.currentProfile
            )
        }
        .sheet(item: $showingRoutineDetail) { template in
            RoutineDetailView(template: template)
        }
        .onAppear {
            templateManager.loadTemplates(for: workoutManager.currentProfile)
        }
    }

    // MARK: - Saved Templates Section
    private var savedTemplatesSection: some View {
        VStack(spacing: 12) {
            if savedTemplates.isEmpty {
                emptyStateView
            } else {
                ForEach(savedTemplates) { template in
                    TemplateCard(
                        template: template,
                        onTap: {
                            showingRoutineDetail = template
                        },
                        onLoad: {
                            workoutManager.loadTemplate(template)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(spacing: 12) {
            if recentWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Recent Workouts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                    Text("Complete workouts to see them here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(recentWorkouts, id: \.date) { workout in
                    RecentWorkoutCard(
                        date: workout.date,
                        entries: workout.entries,
                        onRepeat: {
                            workoutManager.loadFromLogEntries(workout.entries)
                        },
                        onSave: {
                            showingSaveSheet = true
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Saved Routines")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)

            Text("Save your workouts as routines to quickly repeat them later")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showingSaveSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Routine")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ThemeManager.shared.primary)
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Repeat Last Workout Card
struct RepeatLastWorkoutCard: View {
    let date: Date
    let exerciseCount: Int
    let onRepeat: () -> Void

    var body: some View {
        Button(action: onRepeat) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ThemeManager.shared.primary.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title)
                        .foregroundColor(ThemeManager.shared.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat Last Workout")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)

                    HStack(spacing: 6) {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("•")
                            .foregroundColor(.gray)

                        Text("\(exerciseCount) exercises")
                            .font(.caption)
                            .foregroundColor(ThemeManager.shared.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(ThemeManager.shared.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThemeManager.shared.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onLoad: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Tappable area for details
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(ThemeManager.shared.primary)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text("\(template.exercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if let lastUsed = template.lastUsedAt {
                                Text("•")
                                    .foregroundColor(.gray)
                                Text("Used \(formatRelativeDate(lastUsed))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Load button
            Button(action: onLoad) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(ThemeManager.shared.primary)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(ThemeManager.shared.card)
        .cornerRadius(12)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
}

// MARK: - Recent Workout Card
struct RecentWorkoutCard: View {
    let date: Date
    let entries: [WorkoutLogEntry]
    let onRepeat: () -> Void
    let onSave: () -> Void

    private var uniqueExercises: [String] {
        Array(Set(entries.map { $0.exerciseName })).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(formatDate(date))
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)

                Spacer()

                Text("\(uniqueExercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
            }

            // Exercise preview
            Text(uniqueExercises.prefix(4).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onRepeat) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("Repeat")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.primary)
                    .cornerRadius(16)
                }

                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark")
                            .font(.caption)
                        Text("Save")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(ThemeManager.shared.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.card)
                    .cornerRadius(16)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(ThemeManager.shared.card)
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    RoutinesView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.light)
}
