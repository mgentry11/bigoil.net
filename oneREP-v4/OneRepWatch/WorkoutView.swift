#if os(watchOS)
//
//  WorkoutView.swift
//  OneRepWatch v4
//
//  Redesigned Watch workout view with v4 dark theme and circular timer
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var connectivityManager: LocalWatchConnectivityManager
    var state: LocalWatchWorkoutState { connectivityManager.workoutState }

    // V4 Theme Colors
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    private let cardBackground = Color(red: 0.102, green: 0.102, blue: 0.122)

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                // Exercise Name
                Text(state.exerciseName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Weight badge or Next Exercise (during rest)
                if state.phase.lowercased().contains("rest") {
                    if let nextExercise = state.nextExerciseName {
                        VStack(spacing: 2) {
                            Text("NEXT")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.gray)
                            Text(nextExercise)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(accentOrange)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accentOrange.opacity(0.15))
                        .cornerRadius(8)
                    }
                } else if state.weight > 0 {
                    Text("\(Int(state.weight)) lbs")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(accentOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(accentOrange.opacity(0.2))
                        .cornerRadius(8)
                }

                // Circular Timer
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            phaseColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: state.timeRemaining)

                    // Timer content
                    VStack(spacing: 0) {
                        Text("\(state.timeRemaining)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        Text(state.phase.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(phaseColor)
                            .tracking(0.5)
                    }
                }
                .frame(width: 100, height: 100)

                // Control buttons
                HStack(spacing: 12) {
                    // Pause/Play button
                    Button(action: {
                        connectivityManager.sendCommand(state.isRunning ? .pause : .resume)
                    }) {
                        Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(state.isRunning ? .yellow : .green)
                            )
                    }
                    .buttonStyle(.plain)

                    // Skip button
                    Button(action: {
                        connectivityManager.sendCommand(.skip)
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)

                    // Stop button
                    Button(action: {
                        connectivityManager.sendCommand(.stop)
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    var progress: CGFloat {
        guard state.phaseDuration > 0 else { return 0 }
        return CGFloat(state.timeRemaining) / CGFloat(state.phaseDuration)
    }

    var phaseColor: Color {
        switch state.phase.lowercased() {
        case "eccentric", "lower":
            return Color(red: 0.4, green: 0.5, blue: 0.9) // Blue
        case "concentric", "push":
            return accentOrange // Orange
        case "final eccentric", "final negative":
            return Color(red: 0.7, green: 0.4, blue: 0.8) // Purple
        case "rest", "recover":
            return Color(red: 0.3, green: 0.7, blue: 0.7) // Teal
        case "prep", "get ready":
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Gray
        case "position", "positioning":
            return Color(red: 0.8, green: 0.7, blue: 0.3) // Yellow
        case "complete":
            return Color(red: 0.3, green: 0.8, blue: 0.4) // Green
        default:
            return accentOrange
        }
    }
}
#endif
