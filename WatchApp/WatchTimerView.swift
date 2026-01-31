//
//  WatchTimerView.swift
//  OneRepStrength Watch App
//
//  Timer view for Apple Watch during active workout
//

import SwiftUI

struct WatchTimerView: View {
    @ObservedObject var connectivity = WatchConnectivityManager.shared
    
    var state: WatchWorkoutState {
        connectivity.workoutState
    }
    
    var body: some View {
        ZStack {
            // Phase-based background color
            phaseBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Exercise name
                Text(state.exerciseName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                // Phase indicator
                Text(state.phase.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(phaseColor)
                    .tracking(1)
                
                // Large countdown
                Text("\(state.timeRemaining)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                // Progress ring
                ProgressView(
                    value: progress,
                    total: 1.0
                )
                .progressViewStyle(.circular)
                .tint(phaseColor)
                .scaleEffect(0.8)
                
                // Control buttons
                HStack(spacing: 20) {
                    // Pause/Resume
                    Button(action: togglePause) {
                        Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    // Skip phase
                    Button(action: skipPhase) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    var progress: Double {
        guard state.phaseDuration > 0 else { return 0 }
        return Double(state.phaseDuration - state.timeRemaining) / Double(state.phaseDuration)
    }
    
    var phaseColor: Color {
        switch state.phase.lowercased() {
        case "lower", "eccentric":
            return .blue
        case "push", "concentric":
            return .orange
        case "final negative", "final eccentric":
            return .purple
        case "complete":
            return .green
        default:
            return .gray
        }
    }
    
    var phaseBackgroundColor: Color {
        switch state.phase.lowercased() {
        case "lower", "eccentric":
            return Color(red: 0.1, green: 0.2, blue: 0.35)
        case "push", "concentric":
            return Color(red: 0.35, green: 0.2, blue: 0.1)
        case "final negative", "final eccentric":
            return Color(red: 0.25, green: 0.1, blue: 0.3)
        case "complete":
            return Color(red: 0.1, green: 0.3, blue: 0.15)
        default:
            return Color(red: 0.15, green: 0.15, blue: 0.18)
        }
    }
    
    // MARK: - Actions
    
    func togglePause() {
        if state.isRunning {
            WatchConnectivityManager.shared.sendCommand(.pause)
        } else {
            WatchConnectivityManager.shared.sendCommand(.resume)
        }
    }
    
    func skipPhase() {
        WatchConnectivityManager.shared.sendCommand(.skip)
    }
}

// MARK: - Preview
#Preview {
    WatchTimerView()
}
