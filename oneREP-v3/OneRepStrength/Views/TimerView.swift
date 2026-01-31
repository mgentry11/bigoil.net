import SwiftUI

struct TimerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @State private var lastAnnouncedPhase: TimerPhase?
    @State private var lastAnnouncedTime: Int = -1
    @State private var showConfetti: Bool = false
    @State private var isPR: Bool = false
    @State private var prWeight: Double = 0
    @State private var isWaitingForAudio: Bool = false
    @State private var pendingNumber: Int? = nil

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

    var body: some View {
        ZStack {
            phaseBackgroundColor.ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: workoutManager.currentPhase)
            
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
            
            if isPR {
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
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.yellow, lineWidth: 3)
                            )
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 0)
                    .transition(.scale.combined(with: .opacity))
                    
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                HStack {
                    Button(action: { workoutManager.stopTimer() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text(workoutManager.currentExercise?.name ?? "Exercise")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 32)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 8) {
                    Text(phaseDisplayName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text("\(workoutManager.timeRemaining)")
                        .font(.system(size: 160, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .accessibilityLabel("\(workoutManager.timeRemaining) seconds remaining")
                        .contentTransition(.numericText())

                    Text(phaseInstruction)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap to pause/resume
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    workoutManager.toggleTimer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(phaseDisplayName) phase, \(workoutManager.timeRemaining) seconds remaining, \(phaseInstruction)")
                .accessibilityHint("Tap to pause or resume timer")

                Spacer()

                // Controls
                if workoutManager.currentPhase == .complete {
                    // Complete state - Log weight/duration and continue
                    VStack(spacing: 20) {
                        // Weight or Duration input section based on exercise type
                        if isBodyweightExercise {
                            // Duration display for bodyweight exercises
                            VStack(spacing: 12) {
                                Text("Time Completed")
                                    .font(.headline)
                                    .foregroundColor(themeManager.text)

                                // Show the total phase time as duration
                                VStack(spacing: 2) {
                                    Text(formatDuration(currentDuration))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primary)
                                    Text("seconds")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                Text("Bodyweight Exercise")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(themeManager.card)
                            .cornerRadius(16)
                        } else {
                            // Weight input for weighted exercises
                            VStack(spacing: 12) {
                                Text("Log Weight")
                                    .font(.headline)
                                    .foregroundColor(themeManager.text)

                                HStack(spacing: 16) {
                                    // Decrease weight
                                    Button(action: { adjustWeight(-5) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }

                                    // Weight display
                                    VStack(spacing: 2) {
                                        Text("\(Int(currentWeight))")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(themeManager.text)
                                        Text("lbs")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 100)

                                    // Increase weight
                                    Button(action: { adjustWeight(5) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(themeManager.primary)
                                    }
                                }

                                // Fine adjustment buttons
                                HStack(spacing: 12) {
                                    Button(action: { adjustWeight(-2.5) }) {
                                        Text("-2.5")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.text)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(themeManager.card)
                                            .cornerRadius(8)
                                    }
                                    Button(action: { adjustWeight(2.5) }) {
                                        Text("+2.5")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.text)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(themeManager.card)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(themeManager.card)
                            .cornerRadius(16)
                        }

                        Button(action: { reachedFailure.toggle() }) {
                            HStack {
                                Image(systemName: reachedFailure ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(reachedFailure ? .green : .gray)
                                Text("Reached Failure")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.text)
                                Spacer()
                            }
                            .padding()
                            .background(themeManager.card)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Next Session")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                Button(action: { adjustmentMode = .weight }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "scalemass.fill")
                                            .font(.caption)
                                        Text("Weight")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(adjustmentMode == .weight ? .black : .gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(adjustmentMode == .weight ? themeManager.primary : Color(white: 0.2))
                                    .cornerRadius(14)
                                }
                                
                                Button(action: { adjustmentMode = .time }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption)
                                        Text("Time")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(adjustmentMode == .time ? .black : .gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(adjustmentMode == .time ? themeManager.primary : Color(white: 0.2))
                                    .cornerRadius(14)
                                }
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 10) {
                                NextSessionButton(
                                    title: "Reduce",
                                    subtitle: adjustmentMode == .time ? "-5 sec" : "-5 lbs",
                                    icon: "arrow.down.circle.fill",
                                    color: .orange,
                                    isSelected: nextSessionChoice == .reduce
                                ) {
                                    nextSessionChoice = .reduce
                                }
                                
                                NextSessionButton(
                                    title: "Same",
                                    subtitle: "Keep it",
                                    icon: "equal.circle.fill",
                                    color: .blue,
                                    isSelected: nextSessionChoice == .same
                                ) {
                                    nextSessionChoice = .same
                                }
                                
                                NextSessionButton(
                                    title: "Increase",
                                    subtitle: adjustmentMode == .time ? "+5 sec" : "+5 lbs",
                                    icon: "arrow.up.circle.fill",
                                    color: .green,
                                    isSelected: nextSessionChoice == .increase
                                ) {
                                    nextSessionChoice = .increase
                                }
                            }
                        }
                        .padding()
                        .background(themeManager.card)
                        .cornerRadius(12)

                        Button(action: { logSetAndDone() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                Text("Log Set")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.primary)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Log set and finish")
                        .accessibilityHint("Saves your set and returns to workout list")

                        HStack(spacing: 12) {
                            Button(action: { logAndStartRest() }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.subheadline)
                                    Text("Rest")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(themeManager.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(themeManager.card)
                                .cornerRadius(12)
                            }
                            .accessibilityLabel("Log set and rest")
                            .accessibilityHint("Saves your set and starts rest timer")

                            Button(action: { logAndAnotherSet() }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.subheadline)
                                    Text("Another Set")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(themeManager.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(themeManager.card)
                                .cornerRadius(12)
                            }
                            .accessibilityLabel("Do another set")
                            .accessibilityHint("Saves your set and restarts timer for another set")
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    HStack(spacing: 32) {
                        Button(action: { workoutManager.resetPhase() }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundColor(themeManager.text)
                                .frame(width: 56, height: 56)
                                .background(themeManager.card)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Reset phase")
                        .accessibilityHint("Restarts the current phase timer")

                        Button(action: { workoutManager.toggleTimer() }) {
                            Image(systemName: workoutManager.isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.black)
                                .frame(width: 72, height: 72)
                                .background(themeManager.primary)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(workoutManager.isTimerRunning ? "Pause timer" : "Resume timer")

                        Button(action: { workoutManager.skipPhase() }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.text)
                                .frame(width: 56, height: 56)
                                .background(themeManager.card)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Skip to next phase")
                    }
                }

                Spacer()
            }
            .padding(.top) // Respect safe area at top
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
            guard newPhase != lastAnnouncedPhase else { return }
            lastAnnouncedPhase = newPhase
            
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

    // MARK: - Weight/Duration Tracking Functions

    private func adjustWeight(_ amount: Double) {
        currentWeight = max(0, currentWeight + amount)
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
        // Sum of eccentric + concentric + final eccentric phases
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
        applyNextSessionChoice()
        workoutManager.logSetAndFinish(currentWeight, reachedFailure: reachedFailure)
    }

    private func logAndStartRest() {
        checkAndShowPR()
        applyNextSessionChoice()
        workoutManager.logSetToHistory(currentWeight, reachedFailure: reachedFailure)
        workoutManager.startRest()
    }

    private func logAndAnotherSet() {
        checkAndShowPR()
        applyNextSessionChoice()
        workoutManager.logSetToHistory(currentWeight, reachedFailure: reachedFailure)
        workoutManager.anotherSet()
    }
    
    private func applyNextSessionChoice() {
        guard let exercise = workoutManager.currentExercise else { return }
        
        let adjustment: Int
        switch nextSessionChoice {
        case .reduce:
            adjustment = -5
        case .same:
            adjustment = 0
        case .increase:
            adjustment = 5
        }
        
        guard adjustment != 0 else { return }
        
        if adjustmentMode == .time {
            var settings = workoutManager.phaseSettings
            settings.eccentricDuration = max(5, settings.eccentricDuration + adjustment)
            settings.concentricDuration = max(5, settings.concentricDuration + adjustment)
            settings.finalEccentricDuration = max(5, settings.finalEccentricDuration + adjustment)
            workoutManager.phaseSettings = settings
            if let data = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(data, forKey: "phaseSettings")
            }
        } else {
            let newWeight = max(0, currentWeight + Double(adjustment))
            workoutManager.updateExerciseWeight(exercise, weight: newWeight)
        }
    }

    var phaseColor: Color {
        switch workoutManager.currentPhase {
        case .prep, .positioning:
            return .gray
        case .eccentric:
            return themeManager.down
        case .concentric:
            return themeManager.up
        case .finalEccentric:
            return themeManager.down
        case .complete:
            return themeManager.primary
        case .rest:
            return themeManager.textDim
        }
    }
    
    var phaseBackgroundColor: Color {
        switch workoutManager.currentPhase {
        case .prep, .positioning:
            return Color(red: 0.2, green: 0.2, blue: 0.25)
        case .eccentric:
            return Color(red: 0.15, green: 0.3, blue: 0.5)
        case .concentric:
            return Color(red: 0.4, green: 0.25, blue: 0.15)
        case .finalEccentric:
            return Color(red: 0.3, green: 0.15, blue: 0.4)
        case .complete:
            return Color(red: 0.15, green: 0.35, blue: 0.2)
        case .rest:
            return Color(red: 0.2, green: 0.2, blue: 0.3)
        }
    }
    
    var phaseDisplayName: String {
        switch workoutManager.currentPhase {
        case .prep:
            return "Get Ready"
        case .positioning:
            return "Position"
        case .eccentric:
            return "Lower"
        case .concentric:
            return "Push"
        case .finalEccentric:
            return "Final Negative"
        case .complete:
            return "Complete"
        case .rest:
            return "Rest"
        }
    }
    
    var phaseInstruction: String {
        switch workoutManager.currentPhase {
        case .prep:
            return "Prepare for exercise"
        case .positioning:
            return "Get into position"
        case .eccentric:
            return "Control the weight down"
        case .concentric:
            return "Push with power"
        case .finalEccentric:
            return "Slow controlled negative"
        case .complete:
            return "Great work!"
        case .rest:
            return "Recover"
        }
    }
}

// MARK: - Phase Indicator
struct PhaseIndicator: View {
    let phase: TimerPhase
    let currentPhase: TimerPhase
    @ObservedObject var themeManager = ThemeManager.shared

    var isActive: Bool {
        phase == currentPhase
    }

    var isPast: Bool {
        // When complete, all phases are past
        if currentPhase == .complete {
            return true
        }
        let phases: [TimerPhase] = [.eccentric, .concentric, .finalEccentric]
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else {
            return false
        }
        return phaseIndex < currentIndex
    }

    var label: String {
        switch phase {
        case .eccentric: return "E"
        case .concentric: return "C"
        case .finalEccentric: return "F"
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isPast ? themeManager.primary : (isActive ? themeManager.primary : themeManager.card))
                .frame(width: 40, height: 40)

            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isPast || isActive ? .black : .gray)
        }
    }
}

// MARK: - Phase Connector
struct PhaseConnector: View {
    var body: some View {
        Rectangle()
            .fill(Color(white: 0.3))
            .frame(width: 24, height: 2)
    }
}

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

struct NextSessionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? color : .gray)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.3) : Color(white: 0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(title) \(subtitle) for next session")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

#Preview {
    TimerView()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
}
