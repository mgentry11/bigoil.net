//
//  TimerManager.swift
//  OneRepStrength
//
//  Multi-phase workout timer with prep → positive → hold → negative → complete
//

import SwiftUI
import Combine

@MainActor
class TimerManager: ObservableObject {
    @Published var currentPhase: TimerPhase = .prep
    @Published var timeRemaining: Int = 5
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentExercise: Exercise?
    @Published var showingTimer: Bool = false
    @Published var voiceEnabled: Bool = true
    
    // Phase durations (customizable)
    var prepDuration: Int = 5
    var positiveDuration: Int = 10
    var holdDuration: Int = 10
    var negativeDuration: Int = 10
    var restDuration: Int = 90
    
    private var timer: Timer?
    private let audio = AudioManager.shared
    
    // MARK: - Timer Control
    func startExercise(_ exercise: Exercise) {
        currentExercise = exercise
        currentPhase = .prep
        timeRemaining = prepDuration
        isRunning = true
        isPaused = false
        showingTimer = true
        
        // Announce exercise
        if voiceEnabled {
            audio.announceExercise(exercise)
        }
        
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func skip() {
        advancePhase()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        showingTimer = false
        currentExercise = nil
    }
    
    func startRest() {
        currentPhase = .rest
        timeRemaining = restDuration
        isRunning = true
        isPaused = false
        startTimer()
    }
    
    // MARK: - Private
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            advancePhase()
            return
        }
        
        // Voice countdown for last 3 seconds
        if voiceEnabled && timeRemaining <= 3 && currentPhase != .complete && currentPhase != .rest {
            audio.announceNumber(timeRemaining)
        }
        
        timeRemaining -= 1
    }
    
    private func advancePhase() {
        timer?.invalidate()
        timer = nil
        
        if let nextPhase = currentPhase.next {
            currentPhase = nextPhase
            timeRemaining = duration(for: nextPhase)
            
            // Announce new phase
            if voiceEnabled {
                audio.announcePhase(nextPhase)
            }
            
            if nextPhase != .complete {
                startTimer()
            } else {
                isRunning = false
            }
        } else if currentPhase == .rest {
            // Rest complete
            stop()
        }
    }
    
    private func duration(for phase: TimerPhase) -> Int {
        switch phase {
        case .prep: return prepDuration
        case .positive: return positiveDuration
        case .hold: return holdDuration
        case .negative: return negativeDuration
        case .complete: return 0
        case .rest: return restDuration
        }
    }
    
    // MARK: - Formatting
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "00:%02d", seconds)
    }
    
    var progress: Double {
        let total = duration(for: currentPhase)
        guard total > 0 else { return 1.0 }
        return Double(total - timeRemaining) / Double(total)
    }
}
