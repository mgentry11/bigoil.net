//
//  WatchConnectivityManager.swift
//  OneRepStrength
//
//  Manages communication between iPhone and Apple Watch
//

import Foundation
import WatchConnectivity

// MARK: - Workout State for Watch
struct WatchWorkoutState: Codable {
    var exerciseName: String
    var phase: String
    var timeRemaining: Int
    var phaseDuration: Int
    var isRunning: Bool
    var weight: Double
    var isActive: Bool
    
    static let inactive = WatchWorkoutState(
        exerciseName: "",
        phase: "",
        timeRemaining: 0,
        phaseDuration: 0,
        isRunning: false,
        weight: 0,
        isActive: false
    )
}

// MARK: - Watch Commands
enum WatchCommand: String, Codable {
    case pause
    case resume
    case skip
    case stop
}

// MARK: - Connectivity Manager
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var workoutState: WatchWorkoutState = .inactive
    @Published var isReachable: Bool = false
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - iPhone → Watch: Send Workout State
    func sendWorkoutState(_ state: WatchWorkoutState) {
        guard let session = session, session.isReachable else { return }
        
        do {
            let data = try JSONEncoder().encode(state)
            let message: [String: Any] = ["workoutState": data]
            
            session.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send workout state: \(error)")
            }
        } catch {
            print("Failed to encode workout state: \(error)")
        }
    }
    
    // MARK: - Watch → iPhone: Send Command
    func sendCommand(_ command: WatchCommand) {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = ["command": command.rawValue]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send command: \(error)")
        }
    }
    
    // MARK: - Update Application Context (for background sync)
    func updateContext(with state: WatchWorkoutState) {
        guard let session = session else { return }
        
        do {
            let data = try JSONEncoder().encode(state)
            try session.updateApplicationContext(["workoutState": data])
        } catch {
            print("Failed to update context: \(error)")
        }
    }
}

// MARK: - WCSession Delegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
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
               let state = try? JSONDecoder().decode(WatchWorkoutState.self, from: data) {
                self.workoutState = state
            }
            
            // Handle commands from Watch (on iPhone side)
            if let commandString = message["command"] as? String,
               let command = WatchCommand(rawValue: commandString) {
                NotificationCenter.default.post(
                    name: .watchCommandReceived,
                    object: nil,
                    userInfo: ["command": command]
                )
            }
        }
    }
    
    // Receive background context updates
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let data = applicationContext["workoutState"] as? Data,
               let state = try? JSONDecoder().decode(WatchWorkoutState.self, from: data) {
                self.workoutState = state
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let watchCommandReceived = Notification.Name("watchCommandReceived")
}
