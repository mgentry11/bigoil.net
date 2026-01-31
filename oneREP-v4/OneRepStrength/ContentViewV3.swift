// ContentViewV3.swift
// Version 3 UI - Simplified navigation with hidden toolbar and expandable menu

import SwiftUI

struct ContentViewV3: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var currentView: AppView = .workouts
    @State private var isMenuExpanded = false
    @State private var showingExercisePicker = false

    enum AppView: String, CaseIterable {
        case workouts = "Workouts"
        case routines = "Routines"
        case stats = "Stats"
        case log = "Log"
        case settings = "Settings"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .workouts: return "dumbbell.fill"
            case .routines: return "folder.fill"
            case .stats: return "chart.line.uptrend.xyaxis"
            case .log: return "list.bullet.rectangle.portrait"
            case .settings: return "gearshape.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    // Check if workout is active but timer/rest view is hidden
    // Show mini status when:
    // 1. Timer is running OR we're paused (still in an active exercise)
    // 2. AND neither the timer nor rest full-screen views are showing
    // 3. AND we have a current exercise (workout in progress)
    private var shouldShowMiniStatus: Bool {
        let hasActiveWorkout = workoutManager.currentExercise != nil && workoutManager.isWorkoutInProgress
        let isTimerActive = workoutManager.isTimerRunning || workoutManager.isPaused
        let viewsHidden = !workoutManager.showingTimer && !workoutManager.showingRest
        return (hasActiveWorkout || isTimerActive) && viewsHidden
    }

    var body: some View {
        ZStack {
            // Background
            ThemeManager.shared.background.ignoresSafeArea()

            // Main content - full screen, no tab bar
            VStack(spacing: 0) {
                // Mini status bar when workout is active but not showing full timer
                if shouldShowMiniStatus {
                    MiniWorkoutStatusBar(
                        onTap: {
                            // Return to timer view
                            if workoutManager.currentPhase == .rest {
                                workoutManager.showingRest = true
                            } else {
                                workoutManager.showingTimer = true
                            }
                        },
                        onSkip: {
                            showingExercisePicker = true
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content based on current view
                switch currentView {
                case .workouts:
                    WorkoutListView()
                case .routines:
                    RoutinesView()
                case .stats:
                    StatsView()
                case .log:
                    LogView()
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                }
            }

            // Overlay dimmer when menu is expanded
            if isMenuExpanded {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuExpanded = false
                        }
                    }
            }

            // Expandable Menu Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ExpandableMenuButton(
                        isExpanded: $isMenuExpanded,
                        currentView: $currentView
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }

            // Timer/Rest overlays
            if workoutManager.showingTimer {
                TimerView()
                    .transition(.move(edge: .bottom))
            }

            if workoutManager.showingRest {
                RestView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: workoutManager.showingTimer)
        .animation(.easeInOut, value: workoutManager.showingRest)
        .animation(.easeInOut, value: shouldShowMiniStatus)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet()
        }
    }
}

// MARK: - Mini Workout Status Bar
struct MiniWorkoutStatusBar: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var voiceService = VoiceCommandService.shared
    let onTap: () -> Void
    let onSkip: () -> Void

    var phaseColor: Color {
        switch workoutManager.currentPhase {
        case .prep: return .gray
        case .positioning: return .yellow
        case .eccentric: return themeManager.down
        case .concentric: return themeManager.up
        case .finalEccentric: return .purple
        case .complete: return .green
        case .rest: return .cyan
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(phaseColor)
                .frame(width: 10, height: 10)

            // Exercise & Phase
            VStack(alignment: .leading, spacing: 2) {
                Text(workoutManager.currentExercise?.name ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(workoutManager.currentPhase.displayName.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(phaseColor)
            }

            Spacer()

            // Timer
            Text("\(workoutManager.timeRemaining)s")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 50)

            // Voice command button (if voice control is enabled)
            if voiceService.isVoiceControlEnabled {
                Button(action: {
                    voiceService.toggleListening()
                }) {
                    Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(voiceService.isListening ? themeManager.primary : .white)
                        .frame(width: 32, height: 32)
                        .background(voiceService.isListening ? themeManager.primary.opacity(0.3) : Color.white.opacity(0.15))
                        .clipShape(Circle())
                        .animation(.easeInOut(duration: 0.2), value: voiceService.isListening)
                }
            }

            // Skip button (for busy/broken machine)
            Button(action: onSkip) {
                Image(systemName: "arrow.right.arrow.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1F"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(phaseColor.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Exercise Picker Sheet (for switching exercises when machine is busy)
struct ExercisePickerSheet: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    // Get incomplete exercises excluding current
    var availableExercises: [Exercise] {
        workoutManager.currentWorkout.exercises.filter {
            !$0.isCompleted && $0.id != workoutManager.currentExercise?.id
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0F").ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header explanation
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.primary)

                        Text("Switch Exercise")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Machine busy or broken?\nSelect another exercise to do instead.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    if availableExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("All exercises completed!")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(availableExercises) { exercise in
                                    Button(action: {
                                        // Switch to this exercise
                                        workoutManager.switchToExercise(exercise)
                                        dismiss()
                                    }) {
                                        HStack(spacing: 14) {
                                            // Exercise icon
                                            ZStack {
                                                Circle()
                                                    .fill(themeManager.primary.opacity(0.2))
                                                    .frame(width: 44, height: 44)

                                                Image(systemName: exerciseSystemIcon(for: exercise.name))
                                                    .font(.system(size: 18))
                                                    .foregroundColor(themeManager.primary)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(exercise.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)

                                                if exercise.isBodyweight {
                                                    Text("\(exercise.lastDuration ?? 60)s")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                } else if let weight = exercise.lastWeight, weight > 0 {
                                                    Text("\(Int(weight)) lbs")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(16)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer()

                    // Cancel button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    // Helper function to get SF Symbol for exercise
    private func exerciseSystemIcon(for exerciseName: String) -> String {
        let name = exerciseName.lowercased()
        if name.contains("press") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("pull") || name.contains("row") {
            return "figure.rowing"
        } else if name.contains("squat") || name.contains("leg") {
            return "figure.strengthtraining.functional"
        } else if name.contains("curl") {
            return "dumbbell.fill"
        } else if name.contains("extension") {
            return "figure.arms.open"
        } else {
            return "dumbbell.fill"
        }
    }
}

// MARK: - Expandable Menu Button
struct ExpandableMenuButton: View {
    @Binding var isExpanded: Bool
    @Binding var currentView: ContentViewV3.AppView
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Menu items (excluding current view)
    private var menuItems: [ContentViewV3.AppView] {
        ContentViewV3.AppView.allCases.filter { $0 != currentView }
    }
    
    var body: some View {
        ZStack {
            // Expanded menu items - fan out in arc
            if isExpanded {
                ForEach(Array(menuItems.enumerated()), id: \.element) { index, item in
                    MenuItemButton(item: item) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentView = item
                            isExpanded = false
                        }
                    }
                    .offset(getOffset(for: index, total: menuItems.count))
                    .opacity(isExpanded ? 1 : 0)
                    .scaleEffect(isExpanded ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(index) * 0.05),
                        value: isExpanded
                    )
                }
            }
            
            // Main button (shows current view icon)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(themeManager.primary.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.primary, themeManager.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: themeManager.primary.opacity(0.5), radius: 10)
                    
                    // Icon
                    Image(systemName: isExpanded ? "xmark" : currentView.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
        }
    }
    
    // Calculate offset for each menu item in an arc
    private func getOffset(for index: Int, total: Int) -> CGSize {
        let angleStep: Double = 35 // degrees between items
        let startAngle: Double = 180 // start from left
        let radius: Double = 90
        
        let angle = startAngle + Double(index) * angleStep
        let radians = angle * .pi / 180
        
        return CGSize(
            width: cos(radians) * radius,
            height: sin(radians) * radius
        )
    }
}

// MARK: - Menu Item Button
struct MenuItemButton: View {
    let item: ContentViewV3.AppView
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(themeManager.primary.opacity(0.5), lineWidth: 1)
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primary)
                }
                
                Text(item.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ContentViewV3()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
}
