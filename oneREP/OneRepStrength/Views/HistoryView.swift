//
//  HistoryView.swift
//  HITCoachPro
//
//  Shows workout history and stats

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var logManager = WorkoutLogManager.shared
    @Environment(\.dismiss) var dismiss

    private var profileLogs: [WorkoutLogEntry] {
        logManager.getLogs(for: workoutManager.currentProfile)
    }

    private var todaySets: Int {
        logManager.getTotalSetsToday(for: workoutManager.currentProfile)
    }

    private var totalSets: Int {
        logManager.getTotalSets(for: workoutManager.currentProfile)
    }

    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.shared.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats header
                    HStack(spacing: 24) {
                        StatBox(title: "Today", value: "\(todaySets)", subtitle: "sets")
                        StatBox(title: "Total", value: "\(totalSets)", subtitle: "sets logged")
                    }
                    .padding()
                    .glassCardBackground()

                    if profileLogs.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Sets Logged Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ThemeManager.shared.text)
                            Text("Complete exercises and tap \"Log Set\" to track your progress")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        // Log list
                        List {
                            ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                                Section {
                                    ForEach(groupedByDate[date] ?? []) { log in
                                        LogRow(log: log)
                                    }
                                } header: {
                                    Text(formatDate(date))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var groupedByDate: [Date: [WorkoutLogEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: profileLogs) { log in
            calendar.startOfDay(for: log.date)
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

// MARK: - Log Row
struct LogRow: View {
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
}
