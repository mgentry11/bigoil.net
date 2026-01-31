//
//  TimerView.swift
//  OneRepStrength v4
//
//  Redesigned circular timer based on mockups (pages 10, 27)
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var logManager = WorkoutLogManager.shared

    @State private var showConfetti: Bool = false
    @State private var isPR: Bool = false
    @State private var prWeight: Double = 0
    @State private var currentWeight: Double = 0
    @State private var currentDuration: Int = 0
    @State private var reachedFailure: Bool = true
    @State private var nextSessionChoice: NextSessionChoice = .same
    @State private var adjustmentMode: AdjustmentMode = .weight

    enum NextSessionChoice {
        case reduce, same, increase
    }

    enum AdjustmentMode {
        case weight, time
    }

    private var isBodyweightExercise: Bool {
        workoutManager.currentExercise?.isBodyweight ?? false
    }

    // Progress for circular ring (0.0 to 1.0)
    private var progress: Double {
        let total = Double(workoutManager.phaseSettings.duration(for: workoutManager.currentPhase))
        guard total > 0 else { return 0 }
        return 1.0 - (Double(workoutManager.timeRemaining) / total)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            // Subtle gradient glow behind timer
            RadialGradient(
                colors: [phaseColor.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 80,
                endRadius: 350
            )
            .ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 10)

                Spacer()

                // Exercise Name
                Text(workoutManager.currentExercise?.name.uppercased() ?? "EXERCISE")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(3)
                    .padding(.bottom, 50)

                // Circular Timer
                circularTimerView
                    .padding(.bottom, 60)

                // Controls
                if workoutManager.currentPhase == .complete {
                    completePhaseControls
                } else {
                    timerControls
                }

                Spacer()

                // Phase progress bar at bottom
                phaseProgressBar
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)

                // Bottom floating menu button
                floatingMenuButton
                    .padding(.bottom, 20)
            }

            // PR Celebration Overlay
            if isPR {
                prCelebrationView
            }
        }
        .onAppear {
            if let exercise = workoutManager.currentExercise {
                if exercise.isBodyweight {
                    currentDuration = calculateTotalPhaseDuration()
                } else {
                    currentWeight = exercise.lastWeight ?? 0
                }
            }
        }
        .onChange(of: workoutManager.currentPhase) { oldPhase, newPhase in
            let generator = UINotificationFeedbackGenerator()
            switch newPhase {
            case .eccentric, .concentric, .finalEccentric:
                generator.notificationOccurred(.warning)
            case .complete:
                generator.notificationOccurred(.success)
            default:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Minimize button - hides timer view but keeps workout running
            Button(action: {
                workoutManager.showingTimer = false
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            // App Logo
            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.primary)
                Text("OneRepStrength")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Stop button - completely stops the workout
            Button(action: { workoutManager.stopTimer() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Circular Timer View
    private var circularTimerView: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 14)
                .frame(width: 280, height: 280)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [phaseColor.opacity(0.6), phaseColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Glow effect on progress head
            Circle()
                .trim(from: max(0, progress - 0.01), to: progress)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .shadow(color: phaseColor.opacity(0.8), radius: 12)
                .animation(.linear(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 8) {
                // Big timer number
                Text("\(workoutManager.timeRemaining)")
                    .font(.system(size: 100, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .shadow(color: phaseColor.opacity(0.4), radius: 15)

                // Seconds label
                Text("SECONDS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(phaseColor.opacity(0.8))
                    .tracking(2)

                // Phase label in pill
                Text(phaseDisplayName.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                    .padding(.top, 8)
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            workoutManager.toggleTimer()
        }
    }

    // MARK: - Timer Controls
    private var timerControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Pause Button
                Button(action: { workoutManager.toggleTimer() }) {
                    HStack(spacing: 8) {
                        Image(systemName: workoutManager.isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(workoutManager.isTimerRunning ? "PAUSE" : "PLAY")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(width: 140, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }

                // Skip Button
                Button(action: { workoutManager.skipPhase() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("SKIP")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .frame(width: 140, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(themeManager.primary)
                    )
                }
            }

            HStack(spacing: 12) {
                // Done Button - marks exercise complete and starts rest
                Button(action: {
                    workoutManager.completeExercise()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("DONE")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(width: 130, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.green.opacity(0.8))
                    )
                }

                // Stop Button - completely stops timer and resets
                Button(action: {
                    workoutManager.stopTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("STOP")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(width: 130, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.red.opacity(0.8))
                    )
                }
            }
        }
    }

    // MARK: - Complete Phase Controls
    private var completePhaseControls: some View {
        VStack(spacing: 16) {
            // Weight/Duration input
            if isBodyweightExercise {
                durationInputView
            } else {
                weightInputView
            }

            // Reached Failure toggle
            Button(action: { reachedFailure.toggle() }) {
                HStack {
                    Image(systemName: reachedFailure ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(reachedFailure ? themeManager.primary : .gray)
                    Text("Reached Failure")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { logAndStartRest() }) {
                    Text("Rest")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 27)
                                .fill(Color.white.opacity(0.12))
                        )
                }

                Button(action: { logSetAndDone() }) {
                    Text("Log Set")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 27)
                                .fill(themeManager.primary)
                        )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Weight Input View
    private var weightInputView: some View {
        HStack {
            Button(action: { adjustWeight(-5) }) {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(Int(currentWeight))")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primary)
                Text("lbs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: { adjustWeight(5) }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background {
            GlassBackground(isActive: true, tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 10, y: 5)
    }

    // MARK: - Duration Input View
    private var durationInputView: some View {
        VStack(spacing: 8) {
            Text("Time Completed")
                .font(.headline)
                .foregroundColor(.white)

            Text(formatDuration(currentDuration))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primary)

            Text("seconds")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background {
            GlassBackground(isActive: true, tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 10, y: 5)
    }

    // MARK: - Phase Progress Bar
    private var phaseProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(themeManager.primary)
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.linear(duration: 0.3), value: progress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Floating Menu Button (Voice Control)
    private var floatingMenuButton: some View {
        VoiceCommandButton()
    }

    // MARK: - PR Celebration View
    private var prCelebrationView: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text("NEW PR!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)

                Text("\(Int(prWeight)) lbs")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Personal Record!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 24)
            .background {
                GlassBackground(isActive: true, tintColor: .yellow, cornerRadius: 20)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.yellow, lineWidth: 3)
            )
            .shadow(color: .yellow.opacity(0.6), radius: 25)

            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helper Properties
    private var phaseColor: Color {
        switch workoutManager.currentPhase {
        case .prep, .positioning:
            return Color.gray
        case .eccentric, .finalEccentric, .concentric:
            return themeManager.primary // Orange for all active phases
        case .complete:
            return Color.green
        case .rest:
            return Color.cyan
        }
    }

    private var phaseDisplayName: String {
        switch workoutManager.currentPhase {
        case .prep: return "Get Ready"
        case .positioning: return "Position"
        case .eccentric: return "Eccentric"
        case .concentric: return "Push"
        case .finalEccentric: return "Final Negative"
        case .complete: return "Complete"
        case .rest: return "Rest"
        }
    }

    // MARK: - Helper Methods
    private func adjustWeight(_ amount: Double) {
        currentWeight = max(0, currentWeight + amount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return "\(mins):\(String(format: "%02d", secs))"
        }
        return "\(seconds)"
    }

    private func calculateTotalPhaseDuration() -> Int {
        let settings = workoutManager.phaseSettings
        return settings.duration(for: .eccentric) +
               settings.duration(for: .concentric) +
               settings.duration(for: .finalEccentric)
    }

    private func checkAndShowPR() {
        guard let exercise = workoutManager.currentExercise else { return }
        let currentPR = logManager.getPersonalRecords(for: workoutManager.currentProfile)[exercise.name] ?? 0

        if currentWeight > currentPR && currentWeight > 0 {
            isPR = true
            prWeight = currentWeight
            showConfetti = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showConfetti = false
                isPR = false
            }
        }
    }

    private func logSetAndDone() {
        checkAndShowPR()
        workoutManager.logSetAndFinish(currentWeight, reachedFailure: reachedFailure)
    }

    private func logAndStartRest() {
        checkAndShowPR()
        workoutManager.logSetToHistory(currentWeight, reachedFailure: reachedFailure)
        workoutManager.startRest()
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
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
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.yellow, .orange, .green, .blue, .purple, .pink, .red]
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 6...12),
                velocity: CGPoint(x: CGFloat.random(in: -2...2), y: CGFloat.random(in: 3...8)),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].velocity.y += 0.1
                particles[i].opacity -= 0.008
            }

            if particles.allSatisfy({ $0.opacity <= 0 }) {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var velocity: CGPoint
    var opacity: Double
}

#Preview {
    TimerView()
        .environmentObject(WorkoutManager())
}
