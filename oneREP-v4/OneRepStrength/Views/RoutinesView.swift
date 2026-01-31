//
//  RoutinesView.swift
//  OneRepStrength v4
//
//  Redesigned routines view based on mockup (page 24)
//

import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var templateManager = WorkoutTemplateManager.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    var onBack: (() -> Void)? = nil

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
        ZStack {
            // Dark background
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                // Tab Selector
                tabSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Quick Action: Repeat Last Workout
                        if let lastWorkout = recentWorkouts.first, selectedTab == .recent {
                            RepeatLastWorkoutCardV4(
                                date: lastWorkout.date,
                                exerciseCount: Set(lastWorkout.entries.map { $0.exerciseName }).count,
                                onRepeat: {
                                    workoutManager.loadFromLogEntries(lastWorkout.entries)
                                }
                            )
                        }

                        switch selectedTab {
                        case .saved:
                            savedTemplatesSection
                        case .recent:
                            recentWorkoutsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }

            // Floating Add Button - positioned above the menu dial
            if selectedTab == .saved {
                VStack {
                    Spacer()
                    floatingAddButton
                        .padding(.bottom, 110)
                }
            }
        }
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

            Text("Routines")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 12) {
            ForEach(RoutinesTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .black : .gray)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? themeManager.primary : Color.white.opacity(0.1))
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Saved Templates Section
    private var savedTemplatesSection: some View {
        VStack(spacing: 12) {
            if savedTemplates.isEmpty {
                emptyStateView
            } else {
                ForEach(savedTemplates) { template in
                    TemplateCardV4(
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
    }

    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(spacing: 12) {
            if recentWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 100, height: 100)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }

                    Text("No Recent Workouts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Complete workouts to see them here")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(recentWorkouts, id: \.date) { workout in
                    RecentWorkoutCardV4(
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
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(themeManager.primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.primary)
            }

            Text("No Saved Routines")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("Save your workouts as routines to quickly repeat them later")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showingSaveSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Create Routine")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(themeManager.primary)
                )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: { showingSaveSheet = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(themeManager.primary)
                        .shadow(color: themeManager.primary.opacity(0.5), radius: 15, y: 5)
                )
        }
    }
}

// MARK: - Repeat Last Workout Card V4

struct RepeatLastWorkoutCardV4: View {
    let date: Date
    let exerciseCount: Int
    let onRepeat: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onRepeat) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.primary.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat Last Workout")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text(formatDate(date))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Text("\(exerciseCount) exercises")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background {
                GlassBackground(isActive: true, tintColor: themeManager.primary, cornerRadius: 16)
            }
            .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.5), radius: 8, y: 4)
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

// MARK: - Template Card V4

struct TemplateCardV4: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onLoad: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 14) {
            // Tappable area for details
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.primary)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text("\(template.exercises.count) exercises")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            if let lastUsed = template.lastUsedAt {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("Used \(formatRelativeDate(lastUsed))")
                                    .font(.system(size: 12))
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
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(themeManager.primary)
                    )
            }
        }
        .padding(16)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
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

// MARK: - Recent Workout Card V4

struct RecentWorkoutCardV4: View {
    let date: Date
    let entries: [WorkoutLogEntry]
    let onRepeat: () -> Void
    let onSave: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    private var uniqueExercises: [String] {
        Array(Set(entries.map { $0.exerciseName })).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(formatDate(date))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(uniqueExercises.count) exercises")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.primary)
            }

            // Exercise preview
            Text(uniqueExercises.prefix(4).joined(separator: ", "))
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(1)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onRepeat) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Repeat")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(themeManager.primary)
                    )
                }

                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 12))
                        Text("Save")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }

                Spacer()
            }
        }
        .padding(16)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
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
        .preferredColorScheme(.dark)
}
