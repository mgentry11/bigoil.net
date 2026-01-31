import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var userName: String = ""
    
    enum ExperienceLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var description: String {
            switch self {
            case .beginner: return "New to HIT training (0-6 months)"
            case .intermediate: return "Some experience (6-24 months)"
            case .advanced: return "Experienced practitioner (2+ years)"
            }
        }
        
        var icon: String {
            switch self {
            case .beginner: return "leaf.fill"
            case .intermediate: return "flame.fill"
            case .advanced: return "bolt.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
    
    var body: some View {
        ZStack {
            ThemeManager.shared.background.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                conceptPage.tag(1)
                levelPage.tag(2)
                readyPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(currentPage == index ? ThemeManager.shared.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                if currentPage < 3 {
                    Button(action: { withAnimation { currentPage += 1 } }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeManager.shared.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundColor(ThemeManager.shared.primary)
            
            Text("Welcome to\nOneRepStrength")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(ThemeManager.shared.text)
            
            Text("High-Intensity Training\nwith precision timing")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private var conceptPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("How HIT Works")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)
            
            VStack(alignment: .leading, spacing: 20) {
                PhaseExplanationRow(
                    phase: "Eccentric",
                    description: "Lower the weight slowly (5-40 sec)",
                    color: ThemeManager.shared.down
                )
                
                PhaseExplanationRow(
                    phase: "Concentric",
                    description: "Push/pull the weight up (5-20 sec)",
                    color: ThemeManager.shared.up
                )
                
                PhaseExplanationRow(
                    phase: "Final Eccentric",
                    description: "Final slow negative to failure (5-40 sec)",
                    color: ThemeManager.shared.down
                )
            }
            .padding(.horizontal)
            
            Text("The app guides you through each phase with audio cues and haptic feedback")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private var levelPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Experience")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)
            
            Text("This helps us recommend the right workout frequency")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Button(action: { selectedLevel = level }) {
                        HStack(spacing: 16) {
                            Image(systemName: level.icon)
                                .font(.title2)
                                .foregroundColor(level.color)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundColor(ThemeManager.shared.text)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if selectedLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(ThemeManager.shared.primary)
                            }
                        }
                        .padding()
                        .background(selectedLevel == level ? ThemeManager.shared.primary.opacity(0.2) : ThemeManager.shared.card)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedLevel == level ? ThemeManager.shared.primary : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're Ready!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ThemeManager.shared.text)
            
            VStack(spacing: 12) {
                TipRow(icon: "hand.tap.fill", text: "Tap exercise card to start timer")
                TipRow(icon: "hand.draw.fill", text: "Long-press for more options")
                TipRow(icon: "speaker.wave.2.fill", text: "Audio cues guide each phase")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: completeOnboarding) {
                Text("Start Training")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeManager.shared.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .padding()
    }
    
    private func completeOnboarding() {
        let profile = UserProfile(
            name: userName,
            age: 30,
            bodyWeight: 150,
            signupDate: Date(),
            experienceLevel: mapToUserProfileLevel(selectedLevel)
        )
        
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "userProfile_P1")
        }
        
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
    
    private func mapToUserProfileLevel(_ level: ExperienceLevel) -> UserProfile.ExperienceLevel {
        switch level {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        }
    }
}

struct PhaseExplanationRow: View {
    let phase: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phase)
                    .font(.headline)
                    .foregroundColor(ThemeManager.shared.text)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(ThemeManager.shared.text)
            
            Spacer()
        }
        .padding()
        .glassCardBackground()
        .cornerRadius(10)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
