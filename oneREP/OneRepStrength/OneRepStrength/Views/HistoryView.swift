//
//  HistoryView.swift
//  OneRepStrength
//
//  Workout history with logs and stats
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var profileManager: ProfileManager
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    ProfileSwitcher(
                        selectedProfile: $profileManager.selectedProfileIndex,
                        profileNames: profileManager.profileNames
                    )
                }
                .padding(.horizontal, DS.l)
                .padding(.top, DS.s)
                .padding(.bottom, DS.l)
                
                // Stats Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.m) {
                    StatCard(
                        title: "Total Sets",
                        value: "\(profileManager.currentProfile.totalSets)",
                        icon: "number",
                        color: .brandGreen
                    )
                    
                    StatCard(
                        title: "Volume",
                        value: formatVolume(profileManager.currentProfile.totalVolume),
                        icon: "scalemass.fill",
                        color: .brandPurple
                    )
                }
                .padding(.horizontal, DS.l)
                .padding(.bottom, DS.l)
                
                // Log List
                if profileManager.currentProfile.workoutLogs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DS.l) {
            Spacer()
            
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)
            
            Text("No workouts yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Text("Complete an exercise to see your history")
                .font(.system(size: 15))
                .foregroundColor(.tertiaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Log List
    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: DS.m) {
                ForEach(groupedLogs, id: \.0) { day, logs in
                    VStack(alignment: .leading, spacing: DS.s) {
                        Text(day)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, DS.xs)
                        
                        ForEach(logs) { log in
                            LogCard(log: log)
                        }
                    }
                }
            }
            .padding(.horizontal, DS.l)
            .padding(.bottom, DS.xxxl)
        }
    }
    
    // MARK: - Helpers
    private var groupedLogs: [(String, [WorkoutLog])] {
        let grouped = Dictionary(grouping: profileManager.currentProfile.workoutLogs) { log in
            log.dayString
        }
        return grouped.sorted { $0.value.first?.date ?? Date() > $1.value.first?.date ?? Date() }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Log Card
struct LogCard: View {
    let log: WorkoutLog
    
    var body: some View {
        HStack(spacing: DS.m) {
            VStack(alignment: .leading, spacing: DS.xs) {
                Text(log.exerciseName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryText)
                
                HStack(spacing: DS.s) {
                    Text("\(Int(log.weight)) lbs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    if log.reachedFailure {
                        Text("💪 Failure")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.brandOrange)
                    }
                }
            }
            
            Spacer()
            
            Text(timeString(from: log.date))
                .font(.system(size: 13))
                .foregroundColor(.tertiaryText)
        }
        .padding(DS.l)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.medium)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    HistoryView(profileManager: ProfileManager.shared)
}
