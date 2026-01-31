import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var userName: String = ""

    private let totalPages = 9

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
                founderStoryPage.tag(1)
                sciencePage.tag(2)
                whyHITPage.tag(3)
                practicalBenefitsPage.tag(4)
                howItWorksPage.tag(5)
                appFeaturesPage.tag(6)
                levelPage.tag(7)
                readyPage.tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack {
                // Skip button at top
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button(action: { withAnimation { currentPage = totalPages - 1 } }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? ThemeManager.shared.primary : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                if currentPage < totalPages - 1 {
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

            Text("Science-Based High-Intensity Training")
                .font(.title3)
                .foregroundColor(ThemeManager.shared.primary)
                .multilineTextAlignment(.center)

            Text("Build more muscle in less time\nwith proven HIT principles")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Founder Story
    private var founderStoryPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Founder icon
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.primary.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.fill")
                        .font(.system(size: 45))
                        .foregroundColor(ThemeManager.shared.primary)
                }

                Text("Why I Built This")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                // Personal story - the injury
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bandage.fill")
                            .foregroundColor(.red)
                        Text("It Started With an Injury")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("I'm Mark, 63 years old, former tech executive. I've been lifting weights for over 40 years—trying every method out there.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("Then I got injured doing a basic bicep curl. Nothing fancy. Just a regular lift that I'd done thousands of times. Throwing the weight around, not really focusing.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("I ended up at a back doctor. The injury took about a month to heal. A month of no training, all from one careless rep.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("As a father of two kids with a wife who's a busy doctor, I can't afford the luxury of injuring myself. That was my wake-up call.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // The Darden connection
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("A Conversation I Never Forgot")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("Back in my 20s, I met Dr. Ellington Darden and we talked about negative-only lifting. He told me about his West Point research on eccentric training.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("That conversation stuck with me for decades. After my injury, I knew it was time to finally commit to this approach.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Why the app
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "app.badge.fill")
                            .foregroundColor(ThemeManager.shared.primary)
                        Text("No App Existed—So I Built One")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("When I looked for an app to support slow, controlled HIT training, I found nothing. Every fitness app is designed for volume—more sets, more reps, more time in the gym.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("So I built OneRepStrength. An app for people who want results without injuries, without guesswork, and without wasting hours at the gym.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Stats
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("40+")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeManager.shared.primary)
                            Text("Years Lifting")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 40)

                        VStack {
                            Text("63")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeManager.shared.primary)
                            Text("Years Old")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 40)

                        VStack {
                            Text("0")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("Injuries Since")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Science Behind HIT
    private var sciencePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("The Science")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                // Historical foundation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Built on Decades of Research")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("High-Intensity Training (HIT) was developed in the 1970s based on the principle that brief, intense exercise stimulates muscle growth more effectively than lengthy workouts.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)

                    Text("Pioneering researchers like Arthur Jones and exercise scientist Dr. Ellington Darden demonstrated that training to momentary muscular failure—the point where you can't complete another rep—activates maximum muscle fibers.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Modern research
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(ThemeManager.shared.primary)
                        Text("Modern Research Confirms")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.primary)
                    }

                    Text("Recent studies (2024) continue to validate these principles:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Single-set training to failure produces significant muscle and strength gains")
                        BulletPoint(text: "Eccentric (negative) training enhances upper limb strength by 55%+ in meta-analyses")
                        BulletPoint(text: "Two 30-minute sessions per week can produce meaningful results")
                        BulletPoint(text: "Older adults (even 90+) safely gain strength up to 174% from baseline")
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Clinical use
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.cyan)
                        Text("Trusted by Healthcare")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("Physical therapy clinics use slow, controlled resistance training for spine rehabilitation and injury recovery. The same principles power this app.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
                .padding()
                .background(Color.cyan.opacity(0.08))
                .cornerRadius(12)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Why HIT Works
    private var whyHITPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("Why HIT Works")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                // Core principle
                VStack(spacing: 16) {
                    Text("Train to Failure")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("When you train to the point where you cannot complete another rep with good form, you achieve full motor unit recruitment. This activates fast-twitch muscle fibers that are essential for growth.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Research shows this stimulus, combined with adequate recovery, triggers the body's adaptive response to build stronger muscles.")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    HITBenefitRow(
                        icon: "clock.fill",
                        title: "Time Efficient",
                        description: "Full workouts in 20-30 minutes, 1-3x per week"
                    )
                    HITBenefitRow(
                        icon: "heart.fill",
                        title: "Total Conditioning",
                        description: "Intense muscular contraction drives cardiovascular adaptation"
                    )
                    HITBenefitRow(
                        icon: "shield.fill",
                        title: "Joint Friendly",
                        description: "Slow, controlled movements reduce injury risk vs. ballistic training"
                    )
                    HITBenefitRow(
                        icon: "arrow.up.right",
                        title: "Progressive Overload",
                        description: "Small weight increases over time drive continuous improvement"
                    )
                    HITBenefitRow(
                        icon: "bed.double.fill",
                        title: "Recovery Focused",
                        description: "Muscles grow during rest—HIT respects this biological reality"
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Practical Benefits (50+ Focused)
    private var practicalBenefitsPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "figure.walk")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("Real Life Benefits")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("Especially effective for adults 50+")
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.shared.primary)

                // Time savings
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("In & Out in Under 30 Minutes")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("No more spending hours at the gym. Get a complete, effective workout and get back to your life. More time with family, hobbies, and the things that matter.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Benefits list
                VStack(spacing: 16) {
                    PracticalBenefitRow(
                        icon: "shield.checkered",
                        iconColor: .blue,
                        title: "Reduced Injury Risk",
                        description: "Slow, controlled movements protect joints and connective tissue—no jerky, ballistic exercises"
                    )

                    PracticalBenefitRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "No Guesswork",
                        description: "The app tells you exactly what to do and when. Follow the timer, reach failure, done."
                    )

                    PracticalBenefitRow(
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
                        title: "Sustainable Consistency",
                        description: "1-3 short sessions per week is easy to maintain for years, not just months"
                    )

                    PracticalBenefitRow(
                        icon: "figure.stand",
                        iconColor: .purple,
                        title: "Maintain Independence",
                        description: "Strength training helps maintain muscle mass, bone density, and functional ability as you age"
                    )

                    PracticalBenefitRow(
                        icon: "bolt.slash.fill",
                        iconColor: .red,
                        title: "No Wasted Effort",
                        description: "Every rep counts. No junk volume, no endless sets, no wondering if you did enough"
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Rehabilitation callout
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .font(.title3)
                            .foregroundColor(.cyan)
                        Text("Used in Clinical Rehabilitation")
                            .font(.headline)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Text("This same approach—slow, controlled resistance training—is used by physical therapists and rehabilitation clinics worldwide for spine rehabilitation, injury recovery, and chronic pain treatment.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineSpacing(3)

                    Text("Equipment based on these principles (like MedX) has been validated in 30+ clinical trials with over 100,000 patients treated.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
                .padding()
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(16)

                // Quote callout
                VStack(spacing: 8) {
                    Text("\"Train smarter, not longer.\"")
                        .font(.headline)
                        .italic()
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("Focus on quality, not quantity. Your time is valuable.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - How It Works
    private var howItWorksPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("How It Works")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("Each exercise follows a precise tempo to maximize muscle engagement")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // The phases
                VStack(alignment: .leading, spacing: 20) {
                    PhaseExplanationRow(
                        phase: "1. Eccentric (Negative)",
                        description: "Lower the weight slowly for 5-30 seconds",
                        color: ThemeManager.shared.down
                    )

                    PhaseExplanationRow(
                        phase: "2. Concentric (Positive)",
                        description: "Push/pull the weight up for 5-20 seconds",
                        color: ThemeManager.shared.up
                    )

                    PhaseExplanationRow(
                        phase: "3. Final Negative",
                        description: "Slow lower to complete failure (5-30 sec)",
                        color: ThemeManager.shared.down
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // Why negatives matter
                VStack(spacing: 12) {
                    Text("Why Emphasize Negatives?")
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("Your muscles can handle 40% more weight during the lowering (eccentric) phase. By slowing this phase down, you create greater mechanical tension on muscle fibers, stimulating more growth.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - App Features
    private var appFeaturesPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "iphone")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("Your HIT Coach")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.shared.text)

                Text("OneRepStrength guides you through every rep")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    AppFeatureRow(
                        icon: "speaker.wave.3.fill",
                        title: "Audio Cues",
                        description: "Voice guidance for each phase transition"
                    )
                    AppFeatureRow(
                        icon: "timer",
                        title: "Precision Timing",
                        description: "Visual countdown keeps you on pace"
                    )
                    AppFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Tracking",
                        description: "Log weights and track improvements"
                    )
                    AppFeatureRow(
                        icon: "person.2.fill",
                        title: "Multiple Profiles",
                        description: "Share the app with training partners"
                    )
                    AppFeatureRow(
                        icon: "play.rectangle.fill",
                        title: "Video Demos",
                        description: "Link YouTube videos to exercises"
                    )
                    AppFeatureRow(
                        icon: "bookmark.fill",
                        title: "Save Routines",
                        description: "Create templates from past workouts"
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }
    
    private var levelPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

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
                            .background(selectedLevel == level ? ThemeManager.shared.primary.opacity(0.2) : Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedLevel == level ? ThemeManager.shared.primary : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }

                // Frequency recommendation
                VStack(spacing: 8) {
                    Text("Recommended Frequency")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(frequencyRecommendation)
                        .font(.headline)
                        .foregroundColor(ThemeManager.shared.primary)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                Spacer(minLength: 120)
            }
            .padding(.horizontal)
        }
    }

    private var frequencyRecommendation: String {
        switch selectedLevel {
        case .beginner: return "2-3 workouts per week"
        case .intermediate: return "2 workouts per week"
        case .advanced: return "1-2 workouts per week"
        }
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

            Text("Remember: Quality over quantity.\nOne set to failure is all you need.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                TipRow(icon: "hand.tap.fill", text: "Tap exercise card to start timer")
                TipRow(icon: "hand.draw.fill", text: "Long-press for more options")
                TipRow(icon: "speaker.wave.2.fill", text: "Audio cues guide each phase")
                TipRow(icon: "bolt.fill", text: "Train to failure, then rest & grow")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: completeOnboarding) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Start Training")
                }
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
        // Only create a new profile if one doesn't exist (first time onboarding)
        let existingProfileData = UserDefaults.standard.data(forKey: "userProfile_P1")
        if existingProfileData == nil {
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
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Research Fact Row
struct ResearchFactRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - HIT Benefit Row
struct HITBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }

            Spacer()
        }
    }
}

// MARK: - App Feature Row
struct AppFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ThemeManager.shared.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bullet Point
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(ThemeManager.shared.primary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
                .lineSpacing(2)
        }
    }
}

// MARK: - Practical Benefit Row
struct PracticalBenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(3)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
