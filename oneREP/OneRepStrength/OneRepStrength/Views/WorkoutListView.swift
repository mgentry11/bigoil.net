//
//  WorkoutListView.swift
//  OneRepStrength
//
//  Main workout list with exercise cards and profile switcher
//

import SwiftUI

struct WorkoutListView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var timerManager: TimerManager
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, DS.l)
                    .padding(.top, DS.s)
                    .padding(.bottom, DS.m)
                
                // Progress
                progressHeader
                    .padding(.horizontal, DS.l)
                    .padding(.bottom, DS.l)
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: DS.m) {
                        ForEach(profileManager.currentProfile.exercises) { exercise in
                            ExerciseCard(exercise: exercise) {
                                timerManager.startExercise(exercise)
                            }
                        }
                    }
                    .padding(.horizontal, DS.l)
                    .padding(.bottom, DS.xxxl)
                }
            }
        }
        .alert("Reset Workout?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                profileManager.resetWorkout()
            }
        } message: {
            Text("This will mark all exercises as incomplete.")
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.xs) {
                Text("OneRepStrength")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryText)
                
                Text("High-Intensity Training")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            ProfileSwitcher(
                selectedProfile: $profileManager.selectedProfileIndex,
                profileNames: profileManager.profileNames
            )
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        HStack {
            // Progress
            VStack(alignment: .leading, spacing: DS.xs) {
                Text("Today's Progress")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                HStack(spacing: DS.s) {
                    Text("\(profileManager.currentProfile.completedExercises)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.brandGreen)
                    
                    Text("of \(profileManager.currentProfile.exercises.count) exercises")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            // Reset Button
            Button(action: { showingResetAlert = true }) {
                HStack(spacing: DS.xs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.secondaryText)
                .padding(.horizontal, DS.m)
                .padding(.vertical, DS.s)
                .background(
                    Capsule()
                        .fill(Color.background)
                )
            }
        }
        .padding(DS.l)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview
#Preview {
    WorkoutListView(
        profileManager: ProfileManager.shared,
        timerManager: TimerManager()
    )
}
