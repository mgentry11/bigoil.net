//
//  OneRepWidgetsBundle.swift
//  OneRepStrength v4
//
//  Bundle entry point for all OneRepStrength widgets
//  Redesigned with v4 dark theme
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
                    HStack(spacing: 6) {
                        Image(systemName: context.state.phase.phaseIcon)
                            .font(.system(size: 16))
                            .foregroundColor(context.state.phase.phaseColor)
                        Text(context.state.phase)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(context.state.phase.phaseColor)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.timeRemaining)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.attributes.exerciseName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(context.state.phase.phaseColor)
                                    .frame(
                                        width: geo.size.width * progressValue(context),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)

                        // Weight if applicable
                        if context.attributes.weight > 0 {
                            Text("\(Int(context.attributes.weight)) lbs")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }

            } compactLeading: {
                Image(systemName: context.state.phase.phaseIcon)
                    .foregroundColor(context.state.phase.phaseColor)
            } compactTrailing: {
                Text("\(context.state.timeRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: context.state.phase.phaseIcon)
                    .foregroundColor(context.state.phase.phaseColor)
            }
        }
    }

    private func progressValue(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Double {
        guard context.state.phaseDuration > 0 else { return 1.0 }
        let completed = Double(context.state.phaseDuration - context.state.timeRemaining)
        return max(0, min(1, completed / Double(context.state.phaseDuration)))
    }
}

// MARK: - Live Activity Lock Screen View
struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    // V4 Theme Colors
    private let backgroundColor = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    private let cardBackground = Color(red: 0.102, green: 0.102, blue: 0.122) // #1A1A1F
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                // Phase indicator
                HStack(spacing: 8) {
                    Image(systemName: context.state.phase.phaseIcon)
                        .font(.system(size: 22))
                        .foregroundColor(context.state.phase.phaseColor)

                    Text(context.state.phase.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(context.state.phase.phaseColor)
                        .tracking(0.5)
                }

                Spacer()

                // Exercise Name
                Text(context.attributes.exerciseName)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 8)

            // Main Timer Row
            HStack(alignment: .bottom) {
                // Big Timer
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(context.state.timeRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .shadow(color: context.state.phase.phaseColor.opacity(0.4), radius: 10)

                    Text("sec")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 14)
                }

                Spacer()

                // Weight Badge
                if context.attributes.weight > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(context.attributes.weight))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("LBS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentOrange.opacity(0.8))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                    )
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [context.state.phase.phaseColor.opacity(0.8), context.state.phase.phaseColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.linear(duration: 1.0), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.top, 12)
        }
        .padding(16)
        .background(backgroundColor)
        .activitySystemActionForegroundColor(Color.black)
    }

    var progress: Double {
        guard context.state.phaseDuration > 0 else { return 1.0 }
        let completed = Double(context.state.phaseDuration - context.state.timeRemaining)
        return max(0, min(1, completed / Double(context.state.phaseDuration)))
    }
}
