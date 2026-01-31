//
//  HistoryView.swift
//  OneRepStrength v4
//
//  Redesigned history view with calendar based on mockups (pages 11, 21)
//

import SwiftUI

// Helper struct for sheet presentation
struct SaveSheetData: Identifiable {
    let id = UUID()
    let date: Date
    let entries: [WorkoutLogEntry]
}

struct HistoryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    var onBack: (() -> Void)? = nil

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var saveSheetData: SaveSheetData?

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var workoutDates: Set<Date> {
        let dates = profileLogs.map { calendar.startOfDay(for: $0.date) }
        return Set(dates)
    }

    private var groupedByDate: [Date: [WorkoutLogEntry]] {
        Dictionary(grouping: profileLogs) { log in
            calendar.startOfDay(for: log.date)
        }
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
                        // Calendar
                        calendarView
                            .padding(.horizontal, 20)

                        // Workout history cards
                        workoutHistoryList
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
            }

            // Floating Add Button - positioned above the menu dial
            VStack {
                Spacer()
                floatingAddButton
                    .padding(.bottom, 110)
            }
        }
        .sheet(item: $saveSheetData) { data in
            SaveLogAsTemplateSheet(
                entries: data.entries,
                date: data.date,
                profile: workoutManager.currentProfile
            )
            .environmentObject(workoutManager)
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

            Text("History")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let date = day {
                        calendarDayView(date: date)
                    } else {
                        Text("")
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 12, y: 6)
    }

    // MARK: - Calendar Day View
    private func calendarDayView(date: Date) -> some View {
        let dayNumber = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let hasWorkout = workoutDates.contains(calendar.startOfDay(for: date))
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button(action: {
            selectedDate = date
        }) {
            ZStack {
                // Background circle for workout days
                if hasWorkout {
                    Circle()
                        .fill(themeManager.primary)
                        .frame(width: 36, height: 36)
                }

                // Selection ring
                if isSelected && !hasWorkout {
                    Circle()
                        .stroke(themeManager.primary, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                // Today indicator
                if isToday && !hasWorkout {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 36, height: 36)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: hasWorkout ? .bold : .medium))
                    .foregroundColor(hasWorkout ? .black : (isToday ? .white : .gray))
            }
        }
        .frame(width: 40, height: 40)
    }

    // MARK: - Workout History List
    private var workoutHistoryList: some View {
        VStack(spacing: 12) {
            ForEach(groupedByDate.keys.sorted(by: >).prefix(10), id: \.self) { date in
                workoutCard(date: date, entries: groupedByDate[date] ?? [])
            }

            if profileLogs.isEmpty {
                emptyStateView
            }
        }
    }

    // MARK: - Workout Card
    private func workoutCard(date: Date, entries: [WorkoutLogEntry]) -> some View {
        let exerciseNames = Array(Set(entries.map { $0.exerciseName })).prefix(4)
        let totalDuration = entries.count * 2 // Rough estimate: 2 min per set

        return VStack(alignment: .leading, spacing: 12) {
            // Header with date and duration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(date))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.primary)

                    Text("\(totalDuration) min")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Time icon
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            // Exercise list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(exerciseNames), id: \.self) { name in
                    let exerciseEntries = entries.filter { $0.exerciseName == name }
                    let maxWeight = exerciseEntries.map { $0.weight }.max() ?? 0

                    HStack(spacing: 8) {
                        // Orange indicator
                        Rectangle()
                            .fill(themeManager.primary)
                            .frame(width: 3, height: 20)
                            .cornerRadius(2)

                        Text(name)
                            .font(.system(size: 14))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(Int(maxWeight)) lbs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    workoutManager.loadFromLogEntries(entries)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Repeat")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.primary)
                    .cornerRadius(8)
                }

                Button(action: {
                    saveSheetData = SaveSheetData(date: date, entries: entries)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 12))
                        Text("Save")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Workouts Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Complete workouts to see your history here")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: {
            // Add manual workout entry
        }) {
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

    // MARK: - Helper Functions
    private func changeMonth(_ value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth() -> [Date?] {
        var days: [Date?] = []

        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return days }

        // Fill in empty days before the month starts
        let startOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Fill in the days of the month
        var currentDate = startOfMonth
        while currentDate < monthInterval.end {
            days.append(currentDate)
            if let next = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = next
            } else {
                break
            }
        }

        return days
    }

    private func formatDate(_ date: Date) -> String {
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

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(ThemeManager.shared.primary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Log Day Actions Row
struct LogDayActionsRow: View {
    let date: Date
    let entries: [WorkoutLogEntry]
    let onRepeat: () -> Void
    let onSave: () -> Void

    private var uniqueExerciseCount: Int {
        Set(entries.map { $0.exerciseName }).count
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRepeat) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                    Text("Repeat")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ThemeManager.shared.primary)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button(action: onSave) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 10))
                    Text("Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(uniqueExerciseCount) exercises")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)
    }
}

// MARK: - Log Row
struct LogEntryRow: View {
    let log: WorkoutLogEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(log.exerciseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("(\(log.workoutType))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Text(formatTime(log.date))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(log.weight)) lbs")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ThemeManager.shared.primary)

                if log.reachedFailure {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("Failure")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutManager())
        .preferredColorScheme(.dark)
}
