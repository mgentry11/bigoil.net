import SwiftUI

struct RestView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var currentTip: String = ""
    @State private var nextWeight: Double = 0
    
    private let restTips = [
        "Stay hydrated - take a sip of water",
        "Control your breathing - slow, deep breaths",
        "Shake out your muscles gently",
        "Focus on the next exercise",
        "Keep your muscles warm and loose",
        "Visualize perfect form for the next set",
        "Recovery happens during rest - embrace it"
    ]

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Button(action: { workoutManager.stopTimer() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Text("REST")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)

                    Spacer()

                    Color.clear.frame(width: 32)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {
                    Text("\(workoutManager.timeRemaining)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("seconds")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rest timer: \(workoutManager.timeRemaining) seconds remaining")

                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.cyan)
                    Text(currentTip)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                if let next = workoutManager.nextExercise {
                    VStack(spacing: 16) {
                        Text("UP NEXT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.5)

                        HStack(spacing: 16) {
                            ExerciseIconView(iconName: next.iconName, size: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(next.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if !next.isBodyweight {
                                    Text("\(Int(nextWeight)) lbs")
                                        .font(.headline)
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(16)
                        
                        if !next.isBodyweight {
                            HStack(spacing: 16) {
                                Button(action: { adjustNextWeight(-5) }) {
                                    Text("-5")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 44)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(10)
                                }
                                
                                Spacer()
                                
                                Text("Adjust weight")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Spacer()
                                
                                Button(action: { adjustNextWeight(5) }) {
                                    Text("+5")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 44)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: { workoutManager.skipRest() }) {
                    Text("Skip Rest")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .accessibilityLabel("Skip rest period")
                .accessibilityHint("Double tap to skip rest and start next exercise")
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            currentTip = restTips.randomElement() ?? restTips[0]
            if let next = workoutManager.nextExercise {
                nextWeight = next.lastWeight ?? 0
            }
        }
    }
    
    private func adjustNextWeight(_ amount: Double) {
        nextWeight = max(0, nextWeight + amount)
        if let next = workoutManager.nextExercise {
            workoutManager.updateExerciseWeight(next, weight: nextWeight)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    RestView()
        .environmentObject(WorkoutManager())
}
