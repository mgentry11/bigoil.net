
//
//  OneRepWidgetsBundle.swift
//  OneRepWidgets
//
//  Bundle entry point for all OneRepStrength widgets
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct OneRepWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        StatsWidget()
        LockScreenWidget()
        WorkoutLiveActivity()
    }
}

// MARK: - Workout Live Activity
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            WorkoutLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.phase.phaseIcon)
                            .foregroundColor(context.state.phase.phaseColor)
                        Text(context.state.phase)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(context.state.phase.phaseColor)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.timeRemaining)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(context.state.phase.phaseColor)
                        .contentTransition(.numericText())
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(context.attributes.exerciseName)
                            .font(.headline)
                        
                        ProgressView(value: Double(context.state.phaseDuration - context.state.timeRemaining), 
                                   total: Double(context.state.phaseDuration))
                            .tint(context.state.phase.phaseColor)
                    }
                }
                
            } compactLeading: {
                Image(systemName: context.state.phase.phaseIcon)
                    .foregroundColor(context.state.phase.phaseColor)
            } compactTrailing: {
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(context.state.phase.phaseColor)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: context.state.phase.phaseIcon)
                    .foregroundColor(context.state.phase.phaseColor)
            }
        }
    }
}

struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Icon and Phase
                HStack(spacing: 6) {
                    Image(systemName: context.state.phase.phaseIcon)
                        .font(.title2)
                        .foregroundColor(context.state.phase.phaseColor)
                    
                    Text(context.state.phase)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(context.state.phase.phaseColor)
                }
                
                Spacer()
                
                // Exercise Name
                Text(context.attributes.exerciseName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.bottom, 8)
            
            HStack(alignment: .bottom) {
                // Big Timer
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .shadow(color: context.state.phase.phaseColor.opacity(0.5), radius: 8)
                
                Text("sec")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 12)
                    .padding(.leading, 4)
                
                Spacer()
                
                // Weight Info
                if context.attributes.weight > 0 {
                    VStack(alignment: .trailing) {
                        Text("\(Int(context.attributes.weight))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(context.state.phase.phaseColor)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.linear(duration: 1.0), value: progress)
                }
            }
            .frame(height: 6)
            .padding(.top, 12)
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .activitySystemActionForegroundColor(Color.black)
    }
    
    var progress: Double {
        guard context.state.phaseDuration > 0 else { return 1.0 }
        let completed = Double(context.state.phaseDuration - context.state.timeRemaining)
        return max(0, min(1, completed / Double(context.state.phaseDuration)))
    }
}
