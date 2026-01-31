//
//  WorkoutLiveActivity.swift
//  OneRepStrengthWidget
//
//  Live Activity displaying workout timer on Dynamic Island and Lock Screen
//

import ActivityKit
import SwiftUI
import WidgetKit

// WorkoutActivityAttributes should be available from shared file

// MARK: - Live Activity Widget
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.phase.phaseIcon)
                            .font(.title2)
                            .foregroundStyle(context.state.phase.phaseColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.phase.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(context.attributes.exerciseName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.timeRemaining)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(context.state.phase.phaseColor)
                            .contentTransition(.numericText())
                        
                        Text("sec")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    ProgressView(
                        value: Double(context.state.phaseDuration - context.state.timeRemaining),
                        total: Double(max(1, context.state.phaseDuration))
                    )
                    .progressViewStyle(.linear)
                    .tint(context.state.phase.phaseColor)
                    .scaleEffect(y: 2)
                    .clipShape(Capsule())
                }
                
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                // Compact leading - phase icon
                Image(systemName: context.state.phase.phaseIcon)
                    .foregroundStyle(context.state.phase.phaseColor)
            } compactTrailing: {
                // Compact trailing - timer
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(context.state.phase.phaseColor)
                    .contentTransition(.numericText())
            } minimal: {
                // Minimal - just the timer
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(context.state.phase.phaseColor)
            }
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Phase indicator
            ZStack {
                Circle()
                .fill(context.state.phase.phaseColor.gradient)
                .frame(width: 50, height: 50)
                
                Image(systemName: context.state.phase.phaseIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Exercise and phase info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.exerciseName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(context.state.phase.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(context.state.phase.phaseColor)
            }
            
            Spacer()
            
            // Timer
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(context.state.phase.phaseColor)
                    .contentTransition(.numericText())
                
                Text("seconds")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
        )
        .activityBackgroundTint(Color.black)
    }
}

// MARK: - Previews
#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes(exerciseName: "Chest Press", weight: 135)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(phase: "Eccentric", timeRemaining: 8, phaseDuration: 10, isRunning: true)
    WorkoutActivityAttributes.ContentState(phase: "Concentric", timeRemaining: 5, phaseDuration: 5, isRunning: true)
    WorkoutActivityAttributes.ContentState(phase: "Complete", timeRemaining: 0, phaseDuration: 0, isRunning: false)
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: WorkoutActivityAttributes(exerciseName: "Chest Press", weight: 135)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(phase: "Eccentric", timeRemaining: 8, phaseDuration: 10, isRunning: true)
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: WorkoutActivityAttributes(exerciseName: "Chest Press", weight: 135)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(phase: "Concentric", timeRemaining: 3, phaseDuration: 5, isRunning: true)
}
