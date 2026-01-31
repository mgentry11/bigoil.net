//
//  TimerView.swift
//  OneRepStrength
//
//  Full-screen workout timer with phase colors and weight logging
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var profileManager: ProfileManager
    @State private var loggedWeight: Double = 0
    @State private var reachedFailure: Bool = false
    @State private var showConfetti: Bool = false
    @State private var isPR: Bool = false
    
    var body: some View {
        ZStack {
            // Phase-colored background
            PhaseGradient(phase: timerManager.currentPhase)
                .animation(.easeInOut(duration: 0.5), value: timerManager.currentPhase)
            
            VStack(spacing: DS.xxl) {
                // Header
                header
                
                Spacer()
                
                if timerManager.currentPhase == .complete {
                    // Weight logging UI
                    completionView
                } else {
                    // Timer display
                    timerDisplay
                }
                
                Spacer()
                
                if timerManager.currentPhase != .complete {
                    // Controls
                    controls
                }
            }
            .padding(DS.xl)
            
            // Confetti for PRs
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if let weight = timerManager.currentExercise?.lastWeight {
                loggedWeight = weight
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { timerManager.stop() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack(spacing: DS.xs) {
                Text(timerManager.currentExercise?.name ?? "Exercise")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(timerManager.currentPhase.rawValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Spacer for balance
            Circle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        VStack(spacing: DS.xl) {
            // Progress Ring
            ZStack {
                ProgressRing(
                    progress: timerManager.progress,
                    color: .white,
                    lineWidth: 8
                )
                .frame(width: 220, height: 220)
                
                VStack(spacing: DS.s) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Text(timerManager.currentPhase.instruction)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
    
    // MARK: - Controls
    private var controls: some View {
        HStack(spacing: DS.xxxl) {
            // Pause/Resume
            TimerControlButton(
                icon: timerManager.isPaused ? "play.fill" : "pause.fill",
                color: .white.opacity(0.3)
            ) {
                if timerManager.isPaused {
                    timerManager.resume()
                } else {
                    timerManager.pause()
                }
            }
            
            // Skip
            TimerControlButton(
                icon: "forward.fill",
                color: .white.opacity(0.3)
            ) {
                timerManager.skip()
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: DS.xl) {
            Text("Log Your Weight")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Weight Adjuster
            HStack(spacing: DS.xl) {
                Button(action: { adjustWeight(-5) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(spacing: DS.xs) {
                    Text("\(Int(loggedWeight))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Text("lbs")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 140)
                
                Button(action: { adjustWeight(5) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Fine adjustment
            HStack(spacing: DS.m) {
                ForEach([-2.5, 2.5], id: \.self) { amount in
                    Button(action: { adjustWeight(amount) }) {
                        Text(amount > 0 ? "+2.5" : "-2.5")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, DS.l)
                            .padding(.vertical, DS.s)
                            .background(Capsule().fill(.white.opacity(0.2)))
                    }
                }
            }
            
            // Failure Toggle
            Button(action: { reachedFailure.toggle() }) {
                HStack(spacing: DS.s) {
                    Image(systemName: reachedFailure ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                    Text("Reached Failure")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, DS.xl)
                .padding(.vertical, DS.m)
                .background(
                    Capsule()
                        .fill(reachedFailure ? .white.opacity(0.3) : .white.opacity(0.15))
                )
            }
            
            // Save Button
            Button(action: saveAndContinue) {
                Text("Save & Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(timerManager.currentPhase.color)
                    .padding(.horizontal, DS.xxxl)
                    .padding(.vertical, DS.l)
                    .background(
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    )
            }
        }
    }
    
    // MARK: - Actions
    private func adjustWeight(_ amount: Double) {
        loggedWeight = max(0, loggedWeight + amount)
    }
    
    private func saveAndContinue() {
        guard let exercise = timerManager.currentExercise else { return }
        
        // Check for PR
        isPR = profileManager.isNewPR(exerciseName: exercise.name, weight: loggedWeight)
        
        // Log the workout
        profileManager.logWorkout(
            exerciseName: exercise.name,
            weight: loggedWeight,
            reachedFailure: reachedFailure
        )
        
        // Show confetti for PR
        if isPR {
            withAnimation {
                showConfetti = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
        
        // Start rest timer
        timerManager.startRest()
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .pink, .cyan, .orange, .green, .purple]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -100...0)
                ),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        withAnimation(.easeIn(duration: 2)) {
            for i in particles.indices {
                particles[i].position.y += UIScreen.main.bounds.height + 200
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview
#Preview {
    TimerView(
        timerManager: {
            let tm = TimerManager()
            tm.currentPhase = .positive
            tm.timeRemaining = 7
            tm.currentExercise = Exercise(name: "Leg Press", lastWeight: 180)
            return tm
        }(),
        profileManager: ProfileManager.shared
    )
}
