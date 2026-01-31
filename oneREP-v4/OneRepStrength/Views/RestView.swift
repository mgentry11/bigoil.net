//
//  RestView.swift
//  OneRepStrength v4
//
//  Redesigned rest view with glassmorphism based on mockup (page 15)
//
//  v2 Changes:
//  - Added .lineLimit(1) and .minimumScaleFactor(0.7) to next exercise name
//    to prevent text overflow for long exercise names
//

import SwiftUI

struct RestView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var nextWeight: Double = 0
    @Environment(\.dismiss) private var dismiss

    // Progress for animation (0.0 to 1.0)
    private var progress: Double {
        let total = Double(workoutManager.phaseSettings.restDuration)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(workoutManager.timeRemaining) / total)
    }

    // Format time remaining into digits
    private var timeDigits: (tens: String, ones: String) {
        let time = workoutManager.timeRemaining
        if time >= 100 {
            return (String(time / 10), String(time % 10))
        } else if time >= 10 {
            return (String(time / 10), String(time % 10))
        } else {
            return ("0", String(time))
        }
    }

    var body: some View {
        ZStack {
            // Dark background with subtle gradient
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E"),
                    Color(hex: "16213E"),
                    Color(hex: "0F0F1A")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle blurred shapes for depth
            GeometryReader { geometry in
                Circle()
                    .fill(themeManager.primary.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.2)

                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -geometry.size.width * 0.2, y: geometry.size.height * 0.5)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 10)

                Spacer()

                // Rest Title
                Text("Rest")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // Big countdown display
                countdownView
                    .padding(.bottom, 40)

                // Next exercise card with glassmorphism
                if let next = workoutManager.nextExercise {
                    nextExerciseCard(exercise: next)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    skipRestButton
                    stopTimerButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let next = workoutManager.nextExercise {
                nextWeight = next.lastWeight ?? 0
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Minimize button - hides rest view but keeps timer running
            Button(action: {
                workoutManager.showingRest = false
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            // App Logo
            HStack(spacing: 6) {
                Text("OneRep")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("Strength")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primary)
            }

            Spacer()

            // Stop button - completely stops the workout
            Button(action: { workoutManager.stopTimer() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Countdown View
    private var countdownView: some View {
        HStack(spacing: 4) {
            // First digit(s) - white
            Text(timeDigits.tens)
                .font(.system(size: 160, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())

            // Last digit - orange
            Text(timeDigits.ones)
                .font(.system(size: 160, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primary)
                .contentTransition(.numericText())
        }
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    // MARK: - Next Exercise Card (Glassmorphism)
    private func nextExerciseCard(exercise: Exercise) -> some View {
        HStack(spacing: 16) {
            // Exercise icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: exerciseIcon(for: exercise))
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Next:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                // v2: Added lineLimit and minimumScaleFactor to prevent overflow
                Text(exercise.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            // Weight adjustment if not bodyweight
            if !exercise.isBodyweight {
                HStack(spacing: 12) {
                    Button(action: { adjustNextWeight(-5) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Text("\(Int(nextWeight))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.primary)
                        .frame(minWidth: 40)

                    Button(action: { adjustNextWeight(5) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(isActive: true, tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.4), radius: 20, y: 10)
    }

    // MARK: - Skip Rest Button
    private var skipRestButton: some View {
        Button(action: { workoutManager.skipRest() }) {
            Text("Skip Rest")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.primary)
                        .shadow(color: themeManager.primary.opacity(0.4), radius: 15, y: 5)
                )
        }
    }

    // MARK: - Stop Timer Button
    private var stopTimerButton: some View {
        Button(action: { workoutManager.stopTimer() }) {
            HStack(spacing: 8) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 16))
                Text("Stop Timer")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                GlassBackground(tintColor: .red, cornerRadius: 12)
            }
            .shadow(color: .red.opacity(themeManager.glassShadowOpacity * 0.2), radius: 8, y: 4)
        }
    }

    // MARK: - Helper Methods
    private func adjustNextWeight(_ amount: Double) {
        nextWeight = max(0, nextWeight + amount)
        if let next = workoutManager.nextExercise {
            workoutManager.updateExerciseWeight(next, weight: nextWeight)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func exerciseIcon(for exercise: Exercise) -> String {
        // Return appropriate SF Symbol based on exercise
        let name = exercise.name.lowercased()
        if name.contains("press") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("pull") || name.contains("row") {
            return "figure.rowing"
        } else if name.contains("squat") || name.contains("leg") {
            return "figure.strengthtraining.functional"
        } else if name.contains("curl") {
            return "dumbbell.fill"
        } else {
            return "dumbbell.fill"
        }
    }
}

#Preview {
    RestView()
        .environmentObject(WorkoutManager())
}
