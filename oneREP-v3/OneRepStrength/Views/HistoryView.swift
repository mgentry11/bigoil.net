
//
//  HistoryView.swift
//  HITCoachPro
//
//  Shows workout history and stats
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDateForSave: Date?
    @State private var selectedEntriesForSave: [WorkoutLogEntry] = []
    @State private var showingSaveSheet = false

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var todaySets: Int {
        logManager.getTotalSetsToday(for: workoutManager.currentProfile)
    }

    private var totalSets: Int {
        logManager.getTotalSets(for: workoutManager.currentProfile)
    }

    private var groupedByDate: [Date: [WorkoutLogEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: profileLogs) { log in
            calendar.startOfDay(for: log.date)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // V3 Header
            HStack {
                Text("History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 10)

            // Stats Headers
            HStack(spacing: 16) {
                StatBox(title: "Today", value: "\(todaySets)", subtitle: "sets")
                StatBox(title: "Total", value: "\(totalSets)", subtitle: "sets logged")
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            if profileLogs.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer().frame(height: 40)
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Sets Logged Yet")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.text)
                    Text("Complete exercises and tap \"Log Set\" to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            } else {
                // Log list
                List {
                    ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                         Section {
                             // Action buttons for this day's workout
                             LogDayActionsRow(
                                 date: date,
                                 entries: groupedByDate[date] ?? [],
                                 onRepeat: {
                                     workoutManager.loadFromLogEntries(groupedByDate[date] ?? [])
                                 },
                                 onSave: {
                                     selectedDateForSave = date
                                     selectedEntriesForSave = groupedByDate[date] ?? []
                                     showingSaveSheet = true
                                 }
                             )

                             ForEach(groupedByDate[date] ?? []) { log in
                                 LogEntryRow(log: log)
                             }
                         } header: {
                             Text(formatDate(date))
                                 .font(.subheadline)
                                 .fontWeight(.semibold)
                                 .foregroundColor(ThemeManager.shared.primary)
                         }
                     }
                     
                     // Helper Spacer for bottom menu (List handles spacing poorly sometimes, but padding works)
                     Section {
                         Spacer().frame(height: 100).listRowBackground(Color.clear)
                     }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(ThemeManager.shared.background)
        .sheet(isPresented: $showingSaveSheet) {
            if let date = selectedDateForSave {
                SaveLogAsTemplateSheet(
                    entries: selectedEntriesForSave,
                    date: date,
                    profile: workoutManager.currentProfile
                )
            }
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
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(ThemeManager.shared.primary)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCardBackground()
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
                        .font(.caption2)
                    Text("Repeat")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ThemeManager.shared.primary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button(action: onSave) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark")
                        .font(.caption2)
                    Text("Save")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(ThemeManager.shared.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCardBackground()
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(uniqueExerciseCount) exercises")
                .font(.caption2)
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
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.text)

                    Text("(\(log.workoutType))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(formatTime(log.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(log.weight)) lbs")
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.primary)

                if log.reachedFailure {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("Failure")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear.background(.thickMaterial))
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
        .preferredColorScheme(.light)
}
