import Foundation
import Combine
import ActivityKit

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
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var progress: Double {
        guard currentExercise != nil else { return 0 }
        let totalDuration = phaseSettings.duration(for: currentPhase)
        guard totalDuration > 0 else { return 1 }
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }

    var nextExercise: Exercise? {
        guard let current = currentExercise,
              let index = currentWorkout.exercises.firstIndex(where: { $0.id == current.id }),
              index + 1 < currentWorkout.exercises.count else {
            return nil
        }
        return currentWorkout.exercises[index + 1]
    }

    // MARK: - Initialization
    init() {
        loadSavedData()
    }

    // MARK: - Profile Selection
    func selectProfile(_ profile: Int) {
        guard profile == 1 || profile == 2 else { return }
        currentProfile = profile
        // Reset workout state for new profile
        completedExercises = 0
        UserDefaults.standard.set(profile, forKey: "currentProfile")
    }

    private func loadWeightsForCurrentWorkout() {
        for i in 0..<currentWorkout.exercises.count {
            let exerciseName = currentWorkout.exercises[i].name
            let key = "exerciseWeight_\(currentProfile)_\(exerciseName)"
            let durationKey = "exerciseDuration_\(currentProfile)_\(exerciseName)"
            let failureKey = "exerciseFailure_\(currentProfile)_\(exerciseName)"
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exerciseName)"

            if currentWorkout.exercises[i].isBodyweight {
                if UserDefaults.standard.object(forKey: durationKey) != nil {
                    currentWorkout.exercises[i].lastDuration = UserDefaults.standard.integer(forKey: durationKey)
                }
            } else {
                if UserDefaults.standard.object(forKey: key) != nil {
                    currentWorkout.exercises[i].lastWeight = UserDefaults.standard.double(forKey: key)
                }
            }
            currentWorkout.exercises[i].reachedFailure = UserDefaults.standard.bool(forKey: failureKey)
            currentWorkout.exercises[i].isCompleted = UserDefaults.standard.bool(forKey: completedKey)
        }
    }

    // MARK: - Timer Control
    func startExercise(_ exercise: Exercise) {
        currentExercise = exercise
        currentPhase = .prep
        timeRemaining = phaseSettings.duration(for: .prep)
        showingTimer = true
        showingRest = false
        startTimer()

        // Start workout duration tracking if not already started
        if !isWorkoutInProgress {
            startWorkoutDurationTracking()
        }
        
        // Start Live Activity
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
        advanceToNextPhase()
    }

    func stopTimer() {
        timer?.invalidate()
        isTimerRunning = false
        isPaused = false
        showingTimer = false
        showingRest = false
        
        // End Live Activity
        endLiveActivity()
    }

    // MARK: - Timer Logic
    private func tick() {
        guard timeRemaining > 0 else {
            advanceToNextPhase()
            return
        }
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
        case .positioning:
            currentPhase = .eccentric
            timeRemaining = phaseSettings.duration(for: .eccentric)
        case .eccentric:
            currentPhase = .concentric
            timeRemaining = phaseSettings.duration(for: .concentric)
        case .concentric:
            currentPhase = .finalEccentric
            timeRemaining = phaseSettings.duration(for: .finalEccentric)
        case .finalEccentric:
            completeExercise()
        case .complete:
            break
        case .rest:
            startNextExercise()
        }
    }

    private func completeExercise() {
        pauseTimer()
        currentPhase = .complete

        // Mark exercise as completed
        if let exercise = currentExercise,
           let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            currentWorkout.exercises[index].isCompleted = true
            completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count

            // Save completion state to UserDefaults
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exercise.name)"
            UserDefaults.standard.set(true, forKey: completedKey)
        }
    }

    func startRest() {
        showingTimer = false
        showingRest = true
        currentPhase = .rest
        timeRemaining = phaseSettings.duration(for: .rest)
        startTimer()
    }

    func skipRest() {
        startNextExercise()
    }
    
    func skipExercise(_ exercise: Exercise) {
        guard let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        currentWorkout.exercises[index].isCompleted = true
        completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count
        
        let completedKey = "exerciseCompleted_\(currentProfile)_\(exercise.name)"
        UserDefaults.standard.set(true, forKey: completedKey)
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
        UserDefaults.standard.set(duration, forKey: durationKey)
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
            // Workout complete
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
            UserDefaults.standard.set(true, forKey: completedKey)
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
    func addExercise(name: String, isBodyweight: Bool = false) {
        let newExercise = Exercise(
            name: name,
            iconName: isBodyweight ? "pull_up.png" : "dumbbell.png",
            audioFileName: "exercise_custom",
            isBodyweight: isBodyweight
        )
        currentWorkout.exercises.append(newExercise)
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

        // Reset completion state for new workout
        for i in 0..<currentWorkout.exercises.count {
            currentWorkout.exercises[i].isCompleted = false
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

        // Reset completion state
        for i in 0..<currentWorkout.exercises.count {
            currentWorkout.exercises[i].isCompleted = false
        }
        completedExercises = 0

        saveCustomWorkout()
    }

    // MARK: - Workout Completion
    /// Finish workout - clears completion checkmarks but keeps weights for next session
    func finishWorkout() {
        // Clear completion state for all exercises in current workout
        for i in 0..<currentWorkout.exercises.count {
            let exerciseName = currentWorkout.exercises[i].name
            let completedKey = "exerciseCompleted_\(currentProfile)_\(exerciseName)"
            UserDefaults.standard.removeObject(forKey: completedKey)
            currentWorkout.exercises[i].isCompleted = false
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
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: failureKey)
            UserDefaults.standard.removeObject(forKey: completedKey)
            currentWorkout.exercises[i].lastWeight = nil
            currentWorkout.exercises[i].reachedFailure = false
            currentWorkout.exercises[i].isCompleted = false
        }

        let customKey = "customWorkout_\(currentProfile)"
        UserDefaults.standard.removeObject(forKey: customKey)

        currentWorkout = .defaultWorkout
        completedExercises = 0
    }

    private func saveCustomWorkout() {
        let key = "customWorkout_\(currentProfile)"
        if let data = try? JSONEncoder().encode(currentWorkout.exercises) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCustomWorkout() {
        let key = "customWorkout_\(currentProfile)"
        if let data = UserDefaults.standard.data(forKey: key),
           let exercises = try? JSONDecoder().decode([Exercise].self, from: data) {
            currentWorkout.exercises = exercises
        }
    }

    private func loadSavedData() {
        if let data = UserDefaults.standard.data(forKey: "phaseSettings"),
           let settings = try? JSONDecoder().decode(PhaseSettings.self, from: data) {
            phaseSettings = settings
        }

        let savedProfile = UserDefaults.standard.integer(forKey: "currentProfile")
        if savedProfile == 1 || savedProfile == 2 {
            currentProfile = savedProfile
        }

        loadCustomWorkout()
        loadWeightsForCurrentWorkout()
        completedExercises = currentWorkout.exercises.filter { $0.isCompleted }.count
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(phaseSettings) {
            UserDefaults.standard.set(data, forKey: "phaseSettings")
        }
    }

    private func saveExerciseWeight(exerciseName: String, weight: Double, reachedFailure: Bool) {
        let key = "exerciseWeight_\(currentProfile)_\(exerciseName)"
        let failureKey = "exerciseFailure_\(currentProfile)_\(exerciseName)"
        UserDefaults.standard.set(weight, forKey: key)
        UserDefaults.standard.set(reachedFailure, forKey: failureKey)
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
            isActive: showingTimer || showingRest
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
