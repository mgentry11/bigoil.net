#if os(watchOS)
import SwiftUI
import Foundation
import WatchConnectivity
import WatchKit

@main
struct OneRepWatchApp: App {
    @StateObject private var connectivityManager = LocalWatchConnectivityManager.shared
    @StateObject private var sessionManager = WorkoutSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
                .environmentObject(sessionManager)
                .onChange(of: connectivityManager.workoutState.isActive) { _, isActive in
                    if isActive {
                        sessionManager.startSession()
                    } else {
                        sessionManager.stopSession()
                    }
                }
        }
    }
}

// MARK: - Workout Session Manager (keeps screen on)
class WorkoutSessionManager: NSObject, ObservableObject {
    private var session: WKExtendedRuntimeSession?

    func startSession() {
        guard session == nil else { return }

        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start()
    }

    func stopSession() {
        session?.invalidate()
        session = nil
    }
}

extension WorkoutSessionManager: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session started")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire")
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Extended runtime session invalidated: \(reason)")
        session = nil
    }
}

// MARK: - Local Watch Connectivity Manager (Embedded)
// Renamed to avoid conflicts with shared manager.

// MARK: - Workout State (Local)
struct LocalWatchWorkoutState: Codable {
    var exerciseName: String
    var phase: String
    var timeRemaining: Int
    var phaseDuration: Int
    var isRunning: Bool
    var weight: Double
    var isActive: Bool
    var nextExerciseName: String?

    static let inactive = LocalWatchWorkoutState(
        exerciseName: "",
        phase: "",
        timeRemaining: 0,
        phaseDuration: 0,
        isRunning: false,
        weight: 0,
        isActive: false,
        nextExerciseName: nil
    )
}

// MARK: - Local Watch Commands
enum LocalWatchCommand: String, Codable {
    case pause
    case resume
    case skip
    case stop
}

// MARK: - Local Connectivity Manager
class LocalWatchConnectivityManager: NSObject, ObservableObject {
    static let shared = LocalWatchConnectivityManager()

    @Published var workoutState: LocalWatchWorkoutState = .inactive
    @Published var isReachable: Bool = false

    private var session: WCSession?
    private var localTimer: Timer?
    private var lastSyncTime: Date?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // Load any existing application context on launch
    func loadInitialContext() {
        guard let session = session else { return }
        if let data = session.receivedApplicationContext["workoutState"] as? Data,
           let state = try? JSONDecoder().decode(LocalWatchWorkoutState.self, from: data) {
            DispatchQueue.main.async {
                self.updateState(state)
            }
        }
    }

    // Update state and manage local timer
    func updateState(_ newState: LocalWatchWorkoutState) {
        let wasActive = workoutState.isActive
        workoutState = newState
        lastSyncTime = Date()

        // Start or stop local timer based on state
        if newState.isActive && newState.isRunning {
            startLocalTimer()
        } else if !newState.isActive {
            stopLocalTimer()
        } else if !newState.isRunning {
            stopLocalTimer()
        }
    }

    // Local timer keeps countdown going even if iPhone messages stop
    private func startLocalTimer() {
        stopLocalTimer()
        localTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Only decrement if we haven't received an update recently (>1.5 seconds)
                if let lastSync = self.lastSyncTime,
                   Date().timeIntervalSince(lastSync) > 1.5,
                   self.workoutState.isRunning,
                   self.workoutState.timeRemaining > 0 {
                    self.workoutState.timeRemaining -= 1
                }
            }
        }
    }

    private func stopLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }
    
    // MARK: - iPhone → Watch: Send Workout State
    func sendWorkoutState(_ state: LocalWatchWorkoutState) {
        guard let session = session, session.isReachable else { return }
        
        do {
            let data = try JSONEncoder().encode(state)
            let message: [String: Any] = ["workoutState": data]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send workout state: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to encode workout state: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Watch → iPhone: Send Command
    func sendCommand(_ command: LocalWatchCommand) {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = ["command": command.rawValue]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send command: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Application Context (for background sync)
    func updateContext(with state: LocalWatchWorkoutState) {
        guard let session = session else { return }
        
        do {
            let data = try JSONEncoder().encode(state)
            try session.updateApplicationContext(["workoutState": data])
        } catch {
            print("Failed to update context: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSession Delegate
extension LocalWatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            // Load any existing workout state after activation
            self.loadInitialContext()
        }
    }
    
    // WatchOS specific delegate
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // Receive real-time messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle workout state from iPhone
            if let data = message["workoutState"] as? Data,
               let state = try? JSONDecoder().decode(LocalWatchWorkoutState.self, from: data) {
                self.updateState(state)
            }
        }
    }
    
    // Receive background context updates
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let data = applicationContext["workoutState"] as? Data,
               let state = try? JSONDecoder().decode(LocalWatchWorkoutState.self, from: data) {
                self.updateState(state)
            }
        }
    }
}
#endif
