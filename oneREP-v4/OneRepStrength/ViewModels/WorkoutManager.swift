import Foundation
import Combine
import ActivityKit
import UIKit

class WorkoutManager: ObservableObject {
    @Published var currentWorkout: Workout = .defaultWorkout
    @Published var currentExercise: Exercise?
    @Published var currentPhase: TimerPhase = .prep
    @Published var timeRemaining: Int = 10
    @Published var isTimerRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var completedExercises: Int = 0
    @Published var showingTimer: Bool = false
    @Published var showingRest: Bool = false
    @Published var phaseSettings: PhaseSettings = PhaseSettings()
    @Published var currentProfile: Int = 1
    @Published var showingProfile: Bool = false

    // MARK: - Workout Duration Tracking
    @Published var workoutStartTime: Date?
    @Published var workoutDuration: TimeInterval = 0
    @Published var isWorkoutInProgress: Bool = false
    private var durationTimer: Timer?

    // MARK: - Private Properties
    // MARK: - Private Properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Dependencies
    var audioManager: AudioManager?

    // MARK: - Computed Properties
    var progress: Double {
        guard currentExercise != nil else { return 0 }
        let totalDuration = phaseSettings.duration(for: currentPhase)
        guard totalDuration > 0 else { return 1 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }

    var nextExercise: Exercise? {
        guard let current = currentExercise,
              let currentIndex = currentWorkout.exercises.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }

        // Find the next incomplete exercise after current position
        for i in (currentIndex + 1)..<currentWorkout.exercises.count {
            let exercise = currentWorkout.exercises[i]
            if !exercise.isCompleted {
                return exercise
            }
        }

        // If no incomplete exercises after current, check from beginning
        for i in 0..<currentIndex {
            let exercise = currentWorkout.exercises[i]
            if !exercise.isCompleted {
                return exercise
            }
        }

        return nil
    }

    // MARK: - Initialization
    init() {
        loadSavedData()
        setupWatchCommandListener()
    }

    // MARK: - Profile Selection
    func selectProfile(_ profile: Int) {
        guard profile == 1 || profile == 2 else { return }
        currentProfile = profile
        // Reset workout state for new profile
        completedExercises = 0
        AppGroup.defaults.set(profile, forKey: "currentProfile")
    }

    private func loadWeightsForCurrentWorkout() {
        for i in 0..<currentWorkout.exercises.count {
            let exerciseName = currentWorkout.exercises[i].name
            let key = "exerciseWeight_\(currentProfile)_\(exerciseName)"
            let durationKey = "exerciseDuration_\(currentProfile)_\(exerciseName)"
            let failureKey = "exerciseFailure_\(currentProfile)_\(exerciseName)"
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exerciseName)"
            let loggedKey = "exerciseLogged_\(currentProfile)_\(exerciseName)"

            if currentWorkout.exercises[i].isBodyweight {
                if AppGroup.defaults.object(forKey: durationKey) != nil {
                    currentWorkout.exercises[i].lastDuration = AppGroup.defaults.integer(forKey: durationKey)
                }
            } else {
                if AppGroup.defaults.object(forKey: key) != nil {
                    currentWorkout.exercises[i].lastWeight = AppGroup.defaults.double(forKey: key)
                }
            }
            currentWorkout.exercises[i].reachedFailure = AppGroup.defaults.bool(forKey: failureKey)
            currentWorkout.exercises[i].isCompleted = AppGroup.defaults.bool(forKey: completedKey)
            currentWorkout.exercises[i].isLogged = AppGroup.defaults.bool(forKey: loggedKey)
        }
    }

    // MARK: - Timer Control
    func startExercise(_ exercise: Exercise) {
        // Ensure any existing timer is stopped before starting a new one
        timer?.invalidate()
        timer = nil

        currentExercise = exercise
        currentPhase = .prep
        timeRemaining = phaseSettings.duration(for: .prep)
        showingTimer = true
        showingRest = false

        // Keep screen awake during workout
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        // Trigger prep audio
        playPhaseAudio(phase: .prep)

        startTimer()

        // Start workout duration tracking if not already started
        if !isWorkoutInProgress {
            startWorkoutDurationTracking()
        }

        // Start Live Activity
        startLiveActivity(for: exercise)
    }

    /// Switch to a different exercise mid-workout (when machine is busy/broken)
    func switchToExercise(_ exercise: Exercise) {
        // Stop current timer
        timer?.invalidate()
        timer = nil

        // Start the new exercise
        currentExercise = exercise
        currentPhase = .prep
        timeRemaining = phaseSettings.duration(for: .prep)
        showingTimer = true
        showingRest = false

        // Trigger prep audio
        playPhaseAudio(phase: .prep)

        startTimer()

        // Update Live Activity
        startLiveActivity(for: exercise)
    }

    // MARK: - Workout Duration Tracking
    func startWorkoutDurationTracking() {
        workoutStartTime = Date()
        workoutDuration = 0
        isWorkoutInProgress = true

        // Start duration timer
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            self.workoutDuration = Date().timeIntervalSince(startTime)
        }
    }

    func stopWorkoutDurationTracking() -> TimeInterval {
        durationTimer?.invalidate()
        durationTimer = nil
        isWorkoutInProgress = false

        let finalDuration = workoutDuration
        workoutDuration = 0
        workoutStartTime = nil

        return finalDuration
    }

    var formattedWorkoutDuration: String {
        let minutes = Int(workoutDuration) / 60
        let seconds = Int(workoutDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startTimer() {
        isTimerRunning = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pauseTimer() {
        isPaused = true
        isTimerRunning = false
        timer?.invalidate()
    }

    func resumeTimer() {
        startTimer()
    }

    func toggleTimer() {
        if isTimerRunning {
            pauseTimer()
        } else {
            resumeTimer()
        }
    }

    func resetPhase() {
        timeRemaining = phaseSettings.duration(for: currentPhase)
        pauseTimer()
    }

    func skipPhase() {
        // Stop audio first to prevent overlap with next phase
        audioManager?.stopAudio()
        advanceToNextPhase()
    }

    func stopTimer() {
        // Stop all audio first
        audioManager?.stopAudio()

        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        isPaused = false
        showingTimer = false
        showingRest = false
        currentPhase = .prep

        // End Live Activity
        endLiveActivity()
    }

    // MARK: - Timer Logic
    private func tick() {
        guard timeRemaining > 0 else {
            advanceToNextPhase()
            return
        }

        // Play audio BEFORE decrement so number matches display
        // Commander audio only - no synthetic voice
        if let audioManager = audioManager {
            let isRest = currentPhase == .rest
            let finalCountdown: Set<Int> = [5, 4, 3, 2, 1]

            // Special handling for rest phase - commander audio only
            if isRest {
                // At 30 seconds, play rest warning
                if timeRemaining == 30 {
                    audioManager.playCountdownNumber(30, isRest: true)
                }
                // At 20 seconds, play "get ready" audio
                else if timeRemaining == 20 {
                    audioManager.playRestGetReady()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                // At 10 seconds, play countdown
                else if timeRemaining == 10 {
                    audioManager.playCountdownNumber(10, isRest: true)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                // Final countdown 5, 4, 3, 2, 1
                else if finalCountdown.contains(timeRemaining) {
                    audioManager.playCountdownNumber(timeRemaining, isRest: true)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            } else {
                // Exercise phase countdown
                let countBy5s: Set<Int> = [30, 20, 15, 10]
                if countBy5s.contains(timeRemaining) {
                    audioManager.playCountdownNumber(timeRemaining, isRest: false)
                    if timeRemaining == 10 {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } else if finalCountdown.contains(timeRemaining) {
                    audioManager.playCountdownNumber(timeRemaining, isRest: false)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            }
        }

        // Decrement AFTER audio trigger
        timeRemaining -= 1

        // Update Live Activity
        updateLiveActivity()

        // Update Watch
        sendWatchState()
    }

    private func advanceToNextPhase() {
        switch currentPhase {
        case .prep:
            currentPhase = .positioning
            timeRemaining = phaseSettings.duration(for: .positioning)
            playPhaseAudio(phase: .positioning)
        case .positioning:
            currentPhase = .eccentric
            if let exercise = currentExercise, exercise.isNegativeOnly {
                // Feature: Negative Only uses the sustained duration (lastDuration) instead of global setting
                timeRemaining = exercise.lastDuration ?? phaseSettings.duration(for: .eccentric)
            } else {
                timeRemaining = phaseSettings.duration(for: .eccentric)
            }
            playPhaseAudio(phase: .eccentric)
        case .eccentric:
            if let exercise = currentExercise, exercise.isNegativeOnly {
                // Feature: Negative Only ends after eccentric phase
                completeExercise()
            } else {
                currentPhase = .concentric
                timeRemaining = phaseSettings.duration(for: .concentric)
                playPhaseAudio(phase: .concentric)
            }
        case .concentric:
            currentPhase = .finalEccentric
            timeRemaining = phaseSettings.duration(for: .finalEccentric)
            playPhaseAudio(phase: .finalEccentric)
        case .finalEccentric:
            completeExercise()
        case .complete:
            break
        case .rest:
            startNextExercise()
        }
    }

    func completeExercise() {
        // Stop audio first to prevent overlap
        audioManager?.stopAudio()

        // Mark exercise as completed AND auto-log it
        if let exercise = currentExercise {
            if let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                currentWorkout.exercises[index].isCompleted = true
                completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count

                // Save completion state to AppGroup.defaults
                let completedKey = "exerciseCompleted_\(currentProfile)_\(exercise.name)"
                AppGroup.defaults.set(true, forKey: completedKey)

                // Auto-log the exercise immediately
                logExercise(currentWorkout.exercises[index])
            }
        }

        // Auto-start rest
        startRest()
    }

    // MARK: - Exercise Logging
    func logExercise(_ exercise: Exercise) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }

        let weight = exercise.lastWeight ?? 0
        WorkoutLogManager.shared.addLog(
            exerciseName: exercise.name,
            workoutType: "workout",
            weight: weight,
            reachedFailure: exercise.reachedFailure,
            profile: currentProfile
        )

        currentWorkout.exercises[index].isLogged = true

        // Save logged state
        let loggedKey = "exerciseLogged_\(currentProfile)_\(exercise.name)"
        AppGroup.defaults.set(true, forKey: loggedKey)
    }

    func logAllCompletedExercises() {
        for exercise in currentWorkout.exercises where exercise.isCompleted && !exercise.isLogged {
            logExercise(exercise)
        }
    }

    var hasUnloggedCompletedExercises: Bool {
        currentWorkout.exercises.contains { $0.isCompleted && !$0.isLogged }
    }

    func startRest() {
        // Stop any existing timer first to prevent double timers
        pauseTimer()

        showingTimer = false
        showingRest = true
        currentPhase = .rest
        let restDuration = phaseSettings.duration(for: .rest)
        timeRemaining = restDuration

        // Play encouragement and rest announcement (commander only, no synthetic voice)
        if let audioManager = audioManager {
            // Play encouragement for completing the exercise
            audioManager.playRandomEncouragement()

            // After encouragement, play "take a break" audio
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard self?.currentPhase == .rest else { return }
                audioManager.playRestStarting()
            }
        }

        // Update Live Activity for rest phase
        updateLiveActivity()

        startTimer()
    }

    private func playPhaseAudio(phase: TimerPhase) {
        guard let audioManager = audioManager, let _ = currentExercise else { return }

        // Stop any playing audio to prevent overlap
        audioManager.stopAudio()

        let (cueText, cueFile): (String, String) = {
            switch phase {
            case .prep: return ("Get ready", "phase_get_ready")
            case .positioning: return ("Position", "phase_position")
            case .eccentric: return ("Eccentric", "phase_eccentric")
            case .concentric: return ("Concentric", "phase_concentric")
            case .finalEccentric: return ("Final eccentric", "phase_final_eccentric")
            case .complete: return ("Exercise complete!", "phase_complete")
            case .rest: return ("Rest", "phase_rest")
            }
        }()

        if phase == .rest {
            audioManager.playCue(cueText, audioFile: cueFile)
            return
        }

        // Get phase duration to decide on encouragement
        let phaseDuration = phaseSettings.duration(for: phase)

        if phase == .eccentric || phase == .concentric || phase == .finalEccentric {
            // Short phases (7 seconds or less): NO encouragement, just the phase cue
            if phaseDuration <= 7 {
                audioManager.playCue(cueText, audioFile: cueFile)
            }
            // Medium phases (8-15 seconds): encouragement at start only
            else if phaseDuration <= 15 {
                audioManager.playCue(cueText, audioFile: cueFile) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        audioManager.playRandomEncouragement()
                    }
                }
            }
            // Long phases (16+ seconds): encouragement at start, schedule mid-phase encouragement
            else {
                audioManager.playCue(cueText, audioFile: cueFile) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        audioManager.playRandomEncouragement()
                    }
                }
                // Mid-phase encouragement at roughly halfway point
                let midPoint = Double(phaseDuration) / 2.0
                DispatchQueue.main.asyncAfter(deadline: .now() + midPoint) { [weak self] in
                    // Only play if still in same phase and timer running
                    guard let self = self,
                          self.currentPhase == phase,
                          self.isTimerRunning else { return }
                    audioManager.playRandomEncouragement()
                }
            }
        } else {
            audioManager.playCue(cueText, audioFile: cueFile)
        }
    }

    func skipRest() {
        // Stop audio first to prevent overlap with next exercise
        audioManager?.stopAudio()
        startNextExercise()
    }

    func skipExercise(_ exercise: Exercise) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentWorkout.exercises[index].isCompleted = true
        completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count

        let completedKey = "exerciseCompleted_\(currentProfile)_\(exercise.name)"
        AppGroup.defaults.set(true, forKey: completedKey)
    }

    func updateExerciseWeight(_ exercise: Exercise, weight: Double) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentWorkout.exercises[index].lastWeight = weight
        saveExerciseWeight(exerciseName: exercise.name, weight: weight, reachedFailure: false)
    }

    func updateExerciseDuration(_ exercise: Exercise, duration: Int) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentWorkout.exercises[index].lastDuration = duration
        let durationKey = "exerciseDuration_\(currentProfile)_\(exercise.name)"
        AppGroup.defaults.set(duration, forKey: durationKey)
    }

    func updateExerciseNegativeOnly(_ exercise: Exercise, isNegativeOnly: Bool) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentWorkout.exercises[index].isNegativeOnly = isNegativeOnly
        let negKey = "exerciseNegative_\(currentProfile)_\(exercise.name)"
        AppGroup.defaults.set(isNegativeOnly, forKey: negKey)
    }

    func anotherSet() {
        guard let exercise = currentExercise else { return }
        startExercise(exercise)
    }

    private func startNextExercise() {
        pauseTimer()
        showingRest = false

        if let next = nextExercise {
            startExercise(next)
        } else {
            // Workout complete - play congratulatory message
            if let audioManager = audioManager {
                audioManager.playWorkoutComplete()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    audioManager.playWorkoutCrushed()
                }
            }
            stopTimer()
        }
    }

    // MARK: - Weight Logging
    func logWeight(_ weight: Double, reachedFailure: Bool) {
        guard let exercise = currentExercise,
              let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return
        }
        currentWorkout.exercises[index].lastWeight = weight
        currentWorkout.exercises[index].reachedFailure = reachedFailure

        // Save to persistent storage
        saveExerciseWeight(exerciseName: exercise.name, weight: weight, reachedFailure: reachedFailure)
    }

    /// Log the set to workout history and mark exercise complete
    func logSetToHistory(_ weight: Double, reachedFailure: Bool) {
        guard let exercise = currentExercise else { return }

        // Save weight to current workout
        logWeight(weight, reachedFailure: reachedFailure)

        // Mark exercise as completed
        if let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            currentWorkout.exercises[index].isCompleted = true
            completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count

            // Save completion state
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exercise.name)"
            AppGroup.defaults.set(true, forKey: completedKey)
        }

        WorkoutLogManager.shared.addLog(
            exerciseName: exercise.name,
            workoutType: "workout",
            weight: weight,
            reachedFailure: reachedFailure,
            profile: currentProfile
        )
    }

    /// Log set and return to workout list
    func logSetAndFinish(_ weight: Double, reachedFailure: Bool) {
        logSetToHistory(weight, reachedFailure: reachedFailure)
        stopTimer()
    }

    // MARK: - Exercise Management
    func addExercise(name: String, isBodyweight: Bool = false, weight: Double? = nil, isNegativeOnly: Bool = false) {
        var newExercise = Exercise(
            name: name,
            iconName: isBodyweight ? "pull_up.png" : "dumbbell.png",
            audioFileName: "exercise_custom",
            isBodyweight: isBodyweight,
            isNegativeOnly: isNegativeOnly
        )
        newExercise.lastWeight = weight
        currentWorkout.exercises.append(newExercise)
        saveCustomWorkout()
    }

    func updateExercise(_ exercise: Exercise, name: String? = nil, weight: Double? = nil, isBodyweight: Bool? = nil, isNegativeOnly: Bool? = nil, youtubeURL: String? = nil) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }

        if let newName = name {
            currentWorkout.exercises[index] = Exercise(
                id: exercise.id,
                name: newName,
                iconName: exercise.iconName,
                audioFileName: exercise.audioFileName,
                lastWeight: weight ?? exercise.lastWeight,
                isBodyweight: isBodyweight ?? exercise.isBodyweight,
                isNegativeOnly: isNegativeOnly ?? exercise.isNegativeOnly,
                youtubeURL: youtubeURL ?? exercise.youtubeURL
            )
        } else {
            if let newWeight = weight {
                currentWorkout.exercises[index].lastWeight = newWeight
            }
            if let newIsBodyweight = isBodyweight {
                currentWorkout.exercises[index].isBodyweight = newIsBodyweight
            }
            if let newIsNegativeOnly = isNegativeOnly {
                currentWorkout.exercises[index].isNegativeOnly = newIsNegativeOnly
            }
            if let newYoutubeURL = youtubeURL {
                currentWorkout.exercises[index].youtubeURL = newYoutubeURL.isEmpty ? nil : newYoutubeURL
            }
        }
        saveCustomWorkout()
    }

    func deleteExercise(_ exercise: Exercise) {
        if let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            currentWorkout.exercises.remove(at: index)
            completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count
            saveCustomWorkout()
        }
    }

    func moveExercise(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < currentWorkout.exercises.count,
              destinationIndex >= 0 && destinationIndex < currentWorkout.exercises.count,
              sourceIndex != destinationIndex else { return }

        let exercise = currentWorkout.exercises.remove(at: sourceIndex)
        currentWorkout.exercises.insert(exercise, at: destinationIndex)
        saveCustomWorkout()
    }

    // MARK: - Template Loading
    /// Load a workout template - replaces current workout exercises with template exercises
    func loadTemplate(_ template: WorkoutTemplate) {
        // Convert template exercises to workout exercises
        let exercises = template.toExercises()

        // Replace current workout exercises
        currentWorkout.exercises = exercises

        // Reset completion and logged state for new workout
        for i in 0..<currentWorkout.exercises.count {
            currentWorkout.exercises[i].isCompleted = false
            currentWorkout.exercises[i].isLogged = false
        }
        completedExercises = 0

        // Save as custom workout so it persists
        saveCustomWorkout()

        WorkoutTemplateManager.shared.updateTemplateLastUsed(template)
    }

    /// Load exercises from workout log entries (repeat a past workout)
    func loadFromLogEntries(_ entries: [WorkoutLogEntry]) {
        // Remove duplicates, keeping the last entry for each exercise
        var exerciseDict: [String: WorkoutLogEntry] = [:]
        for entry in entries {
            exerciseDict[entry.exerciseName] = entry
        }

        // Create exercises from log entries
        let exercises = exerciseDict.values.map { entry in
            Exercise(
                name: entry.exerciseName,
                iconName: "dumbbell.png",
                audioFileName: "exercise_custom",
                lastWeight: entry.weight
            )
        }

        // Replace current workout exercises
        currentWorkout.exercises = exercises

        // Reset completion and logged state
        for i in 0..<currentWorkout.exercises.count {
            currentWorkout.exercises[i].isCompleted = false
            currentWorkout.exercises[i].isLogged = false
        }
        completedExercises = 0

        saveCustomWorkout()
    }

    // MARK: - Workout Completion
    /// Finish workout - clears completion checkmarks but keeps weights for next session
    func finishWorkout() {
        stopTimer() // Ensure any running timer/rest is stopped

        // Clear completion and logged state for all exercises in current workout
        for i in 0..<currentWorkout.exercises.count {
            let exerciseName = currentWorkout.exercises[i].name
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exerciseName)"
            let loggedKey = "exerciseLogged_\(currentProfile)_\(exerciseName)"
            AppGroup.defaults.removeObject(forKey: completedKey)
            AppGroup.defaults.removeObject(forKey: loggedKey)
            currentWorkout.exercises[i].isCompleted = false
            currentWorkout.exercises[i].isLogged = false
        }
        completedExercises = 0
    }

    /// Reset workout - clears everything including weights and custom exercises
    func resetWorkout() {
        // Clear all saved data for current workout
        for i in 0..<currentWorkout.exercises.count {
            let exerciseName = currentWorkout.exercises[i].name
            let key = "exerciseWeight_\(currentProfile)_\(exerciseName)"
            let failureKey = "exerciseFailure_\(currentProfile)_\(exerciseName)"
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exerciseName)"
            let loggedKey = "exerciseLogged_\(currentProfile)_\(exerciseName)"
            AppGroup.defaults.removeObject(forKey: key)
            AppGroup.defaults.removeObject(forKey: failureKey)
            AppGroup.defaults.removeObject(forKey: completedKey)
            AppGroup.defaults.removeObject(forKey: loggedKey)
            currentWorkout.exercises[i].lastWeight = nil
            currentWorkout.exercises[i].reachedFailure = false
            currentWorkout.exercises[i].isCompleted = false
            currentWorkout.exercises[i].isLogged = false
        }

        let customKey = "customWorkout_\(currentProfile)"
        AppGroup.defaults.removeObject(forKey: customKey)

        currentWorkout = .defaultWorkout
        completedExercises = 0
    }

    private func saveCustomWorkout() {
        let key = "customWorkout_\(currentProfile)"
        if let data = try? JSONEncoder().encode(currentWorkout.exercises) {
            AppGroup.defaults.set(data, forKey: key)
        }
    }

    private func loadCustomWorkout() {
        let key = "customWorkout_\(currentProfile)"
        if let data = AppGroup.defaults.data(forKey: key),
           let exercises = try? JSONDecoder().decode([Exercise].self, from: data) {
            currentWorkout.exercises = exercises
        }
    }

    private func loadSavedData() {
        if let data = AppGroup.defaults.data(forKey: "phaseSettings"),
           let settings = try? JSONDecoder().decode(PhaseSettings.self, from: data) {
            phaseSettings = settings
        }

        let savedProfile = AppGroup.defaults.integer(forKey: "currentProfile")
        if savedProfile == 1 || savedProfile == 2 {
            currentProfile = savedProfile
        }

        loadCustomWorkout()
        loadWeightsForCurrentWorkout()
        completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(phaseSettings) {
            AppGroup.defaults.set(data, forKey: "phaseSettings")
        }
    }

    private func saveExerciseWeight(exerciseName: String, weight: Double, reachedFailure: Bool) {
        let key = "exerciseWeight_\(currentProfile)_\(exerciseName)"
        let failureKey = "exerciseFailure_\(currentProfile)_\(exerciseName)"
        AppGroup.defaults.set(weight, forKey: key)
        AppGroup.defaults.set(reachedFailure, forKey: failureKey)
    }

    // MARK: - Live Activity Support
    private var currentActivity: Activity<WorkoutActivityAttributes>?

    /// Start a Live Activity when exercise begins
    private func startLiveActivity(for exercise: Exercise) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first
        endLiveActivity()

        let attributes = WorkoutActivityAttributes(
            exerciseName: exercise.name,
            weight: exercise.lastWeight ?? 0
        )

        let phaseDuration = phaseSettings.duration(for: currentPhase)
        let state = WorkoutActivityAttributes.ContentState(
            phase: currentPhase.displayName,
            timeRemaining: timeRemaining,
            phaseDuration: phaseDuration,
            isRunning: true
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Live Activity with current timer state
    private func updateLiveActivity() {
        guard let activity = currentActivity else { return }

        let phaseDuration = phaseSettings.duration(for: currentPhase)
        let state = WorkoutActivityAttributes.ContentState(
            phase: currentPhase.displayName,
            timeRemaining: timeRemaining,
            phaseDuration: phaseDuration,
            isRunning: isTimerRunning
        )

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    /// End the Live Activity
    private func endLiveActivity() {
        // Re-enable screen lock when workout ends
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }

        guard let activity = currentActivity else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            phase: "Complete",
            timeRemaining: 0,
            phaseDuration: 0,
            isRunning: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }
        currentActivity = nil
    }

    // MARK: - Watch Connectivity Support

    /// Send current workout state to Watch
    private func sendWatchState() {
        guard let exercise = currentExercise else {
            // Send inactive state
            WatchConnectivityManager.shared.sendWorkoutState(.inactive)
            return
        }

        let state = WatchWorkoutState(
            exerciseName: exercise.name,
            phase: currentPhase.displayName,
            timeRemaining: timeRemaining,
            phaseDuration: phaseSettings.duration(for: currentPhase),
            isRunning: isTimerRunning,
            weight: exercise.lastWeight ?? 0,
            isActive: showingTimer || showingRest,
            nextExerciseName: nextExercise?.name
        )

        WatchConnectivityManager.shared.sendWorkoutState(state)
    }

    /// Setup listener for commands from Watch
    func setupWatchCommandListener() {
        NotificationCenter.default.addObserver(
            forName: .watchCommandReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let command = notification.userInfo?["command"] as? WatchCommand else { return }
            self?.handleWatchCommand(command)
        }
    }

    private func handleWatchCommand(_ command: WatchCommand) {
        switch command {
        case .pause:
            pauseTimer()
        case .resume:
            resumeTimer()
        case .skip:
            skipPhase()
        case .stop:
            stopTimer()
        }
    }

}
