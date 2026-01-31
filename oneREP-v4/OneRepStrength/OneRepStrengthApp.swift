import SwiftUI
import UIKit

@main
struct OneRepStrengthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var audioManager = AudioManager()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentViewV3()
                    .environmentObject(workoutManager)
                    .environmentObject(audioManager)
                    .preferredColorScheme(.dark)
                    .task {
                        SharedWorkoutManager.shared.workoutManager = workoutManager
                        workoutManager.audioManager = audioManager

                        // Setup voice command handling
                        setupVoiceCommands()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        handleScenePhaseChange(newPhase)
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "onerepstrength" else { return }
        switch url.host {
        case "workout", "start":
            if let firstExercise = workoutManager.currentWorkout.exercises.first {
                workoutManager.startExercise(firstExercise)
            }
        default:
            break
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if workoutManager.isTimerRunning {
                workoutManager.pauseTimer()
            }
            audioManager.stopAudio()
        case .inactive:
            break
        case .active:
            // Audio session is configured on-demand in playAudioFile()
            // Don't reconfigure here as it can break VoiceCommandService mic
            break
        @unknown default:
            break
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionManager.shared.pendingAction = shortcutItem.type
        }
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        return configuration
    }
}

class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    @Published var pendingAction: String?
}

// MARK: - Voice Command Setup
extension OneRepStrengthApp {
    private func setupVoiceCommands() {
        let voiceService = VoiceCommandService.shared

        // Update known exercises from current workout
        let exerciseNames = workoutManager.currentWorkout.exercises.map { $0.name }
        voiceService.updateKnownExercises(exerciseNames)

        // Handle voice commands
        voiceService.onCommand = { [weak workoutManager] command in
            guard let manager = workoutManager else { return }
            manager.handleVoiceCommand(command)
        }
    }
}
