//
//  SettingsView.swift
//  OneRepStrength v4
//
//  Redesigned settings view based on mockups (pages 16, 18, 25)
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var audioManager: AudioManager
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Color Theme Section
                        themeSection

                        // Glass Effect Section
                        glassEffectSection

                        // Voice Options Section
                        voiceSection

                        // Voice Control Section (Speech Recognition)
                        voiceControlSection

                        // Phase Timing Section
                        phaseTimingSection

                        // Sync & Tools Section
                        syncToolsSection

                        // Help Section
                        helpSection

                        // About Section
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { if let onBack { onBack() } else { dismiss() } }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Theme")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeCardV4(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.currentTheme = theme
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Glass Effect Section
    private var glassEffectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Glass Effect")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                // Preview card
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Glassmorphism")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Preview of glass effect")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(16)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .opacity(themeManager.glassIntensity)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.glassHighlightOpacity),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.glassBorderOpacity),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity), radius: 12, y: 6)

                // Intensity slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Intensity")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(Int(themeManager.glassIntensity * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(themeManager.primary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Slider(value: $themeManager.glassIntensity, in: 0...1, step: 0.1)
                            .tint(themeManager.primary)

                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.primary)
                    }
                }

                // Quick presets
                HStack(spacing: 10) {
                    GlassPresetButton(title: "None", value: 0, current: themeManager.glassIntensity) {
                        withAnimation { themeManager.glassIntensity = 0 }
                    }
                    GlassPresetButton(title: "Subtle", value: 0.3, current: themeManager.glassIntensity) {
                        withAnimation { themeManager.glassIntensity = 0.3 }
                    }
                    GlassPresetButton(title: "Medium", value: 0.6, current: themeManager.glassIntensity) {
                        withAnimation { themeManager.glassIntensity = 0.6 }
                    }
                    GlassPresetButton(title: "Maximum", value: 1.0, current: themeManager.glassIntensity) {
                        withAnimation { themeManager.glassIntensity = 1.0 }
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(isActive: true, tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 10, y: 5)
    }

    // MARK: - Voice Section
    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voice Options")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                // Standard Voices
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standard Voices")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    HStack(spacing: 10) {
                        VoiceButtonV4(style: .male, currentStyle: audioManager.voiceStyle) {
                            audioManager.voiceStyle = .male
                        }
                        VoiceButtonV4(style: .female, currentStyle: audioManager.voiceStyle) {
                            audioManager.voiceStyle = .female
                        }
                        VoiceButtonV4(style: .digital, currentStyle: audioManager.voiceStyle) {
                            audioManager.voiceStyle = .digital
                        }
                        Spacer()
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Pro Voices
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pro Voices")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    Button(action: { audioManager.voiceStyle = .commander }) {
                        HStack(spacing: 12) {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.primary)
                                .cornerRadius(4)

                            Text("Commander")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            if audioManager.voiceStyle == .commander {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.primary)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(audioManager.voiceStyle == .commander ? themeManager.primary.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(audioManager.voiceStyle == .commander ? themeManager.primary : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }

            // Commander Sound Mapping Link
            if audioManager.voiceStyle == .commander {
                NavigationLink(destination: SoundMappingView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.primary)

                        Text("Map Commander Sounds")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Voice Control Section
    private var voiceControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Voice Control")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Voice control toggle
                Toggle("", isOn: Binding(
                    get: { VoiceCommandService.shared.isVoiceControlEnabled },
                    set: { VoiceCommandService.shared.isVoiceControlEnabled = $0 }
                ))
                .labelsHidden()
                .tint(themeManager.primary)
            }

            VStack(spacing: 12) {
                // Description
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.primary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hands-Free Commands")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Control your workout with voice commands through your earbuds. Tap the play button on your earbuds to activate voice listening.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Authorization status
                if VoiceCommandService.shared.isVoiceControlEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: VoiceCommandService.shared.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(VoiceCommandService.shared.isAuthorized ? .green : .orange)

                        Text(VoiceCommandService.shared.isAuthorized ? "Speech recognition authorized" : "Tap to authorize speech recognition")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .onTapGesture {
                        if !VoiceCommandService.shared.isAuthorized {
                            VoiceCommandService.shared.requestAuthorization { _ in }
                        }
                    }

                    // Always Listening Mode
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\"Hey One Rep\" Wake Word")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Say \"Hey One Rep\" followed by your command while app is open")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { VoiceCommandService.shared.isContinuousListeningEnabled },
                            set: { VoiceCommandService.shared.isContinuousListeningEnabled = $0 }
                        ))
                        .labelsHidden()
                        .tint(themeManager.primary)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)

                    // Listening indicator
                    if VoiceCommandService.shared.isContinuouslyListening {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Listening for \"Hey One Rep\"...")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Available commands
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Say things like:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 4) {
                            voiceCommandExample("\"Hey One Rep, start leg press\"")
                            voiceCommandExample("\"Hey One Rep, next exercise\"")
                            voiceCommandExample("\"Hey One Rep, skip\"")
                            voiceCommandExample("\"Hey One Rep, pause\"")
                            voiceCommandExample("\"Hey One Rep, done\"")
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    private func voiceCommandExample(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "mic.fill")
                .font(.system(size: 8))
                .foregroundColor(themeManager.primary)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Phase Timing Section
    private var phaseTimingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Phase Timing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    workoutManager.phaseSettings = PhaseSettings()
                    UserDefaults.standard.removeObject(forKey: "phaseSettings")
                }) {
                    Text("Reset")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.primary)
                }
            }

            VStack(spacing: 0) {
                PhaseTimingRowV4(title: "Prep", value: $workoutManager.phaseSettings.prepDuration, range: 0...30)
                PhaseTimingRowV4(title: "Positioning", value: $workoutManager.phaseSettings.positioningDuration, range: 0...15)
                PhaseTimingRowV4(title: "Eccentric", value: $workoutManager.phaseSettings.eccentricDuration, range: 10...60)
                PhaseTimingRowV4(title: "Concentric", value: $workoutManager.phaseSettings.concentricDuration, range: 10...60)
                PhaseTimingRowV4(title: "Final Eccentric", value: $workoutManager.phaseSettings.finalEccentricDuration, range: 20...90)
                PhaseTimingRowV4(title: "Rest", value: $workoutManager.phaseSettings.restDuration, range: 30...180, isLast: true)
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Sync & Tools Section
    private var syncToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync & Tools")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                NavigationLink(destination: ScheduleViewV4()) {
                    SettingsRowV4(icon: "calendar", title: "Workout Schedule")
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                NavigationLink(destination: SyncCodeViewV4()) {
                    SettingsRowV4(icon: "arrow.triangle.2.circlepath", title: "Import from Website")
                }

                if let exerciseLibraryURL = URL(string: "https://onerepstrength.com/exercises.html") {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    Link(destination: exerciseLibraryURL) {
                        SettingsRowV4(icon: "globe", title: "Browse Exercise Library", showChevron: false, extraIcon: "arrow.up.right.square")
                    }
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - Help Section
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                Button(action: {
                    hasCompletedOnboarding = false
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.primary)
                            .frame(width: 24)

                        Text("Show Walkthrough")
                            .font(.system(size: 14))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(20)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 20)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 24))
                .foregroundColor(themeManager.primary)

            Text("OneRepStrength")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Theme Card V4

struct ThemeCardV4: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Color preview grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 0),
                    GridItem(.flexible(), spacing: 0)
                ], spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        theme.previewColors[index]
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(theme.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primaryColor.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Voice Button V4

struct VoiceButtonV4: View {
    let style: AudioManager.VoiceStyle
    let currentStyle: AudioManager.VoiceStyle
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var label: String {
        switch style {
        case .male: return "M"
        case .female: return "F"
        case .digital: return "D"
        case .commander: return "C"
        case .elevenLabs: return "AI"
        }
    }

    var isSelected: Bool {
        style == currentStyle
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? themeManager.primary : Color.white.opacity(0.1))
                )
        }
    }
}

// MARK: - Phase Timing Row V4

struct PhaseTimingRowV4: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var isLast: Bool = false
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Spacer()

                Text("\(value)s")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.primary)
                    .frame(width: 44, alignment: .trailing)

                Stepper("", value: $value, in: range)
                    .labelsHidden()
            }
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.1))
            }
        }
    }
}

// MARK: - Settings Row V4

struct SettingsRowV4: View {
    let icon: String
    let title: String
    var showChevron: Bool = true
    var extraIcon: String? = nil
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeManager.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            if let extra = extraIcon {
                Image(systemName: extra)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Sync Code View V4

struct SyncCodeViewV4: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var syncCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Instructions
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.primary.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(themeManager.primary)
                    }

                    Text("Import Exercises")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Enter the 6-character code from the website to import your selected exercises.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)

                // Code Input
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        let char = index < syncCode.count ? String(syncCode[syncCode.index(syncCode.startIndex, offsetBy: index)]) : ""
                        Text(char)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "1A1A1F"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(index < syncCode.count ? themeManager.primary : Color.white.opacity(0.2), lineWidth: 2)
                            )
                    }
                }

                // Hidden text field
                TextField("", text: $syncCode)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .focused($isInputFocused)
                    .onChange(of: syncCode) { oldValue, newValue in
                        let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                        if filtered != syncCode {
                            syncCode = filtered
                        }
                    }

                Button(action: { isInputFocused = true }) {
                    Text("Tap to enter code")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.primary)
                }

                // Messages
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if let success = successMessage {
                    Text(success)
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Import Button
                Button(action: importExercises) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Import Exercises")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(syncCode.count == 6 ? themeManager.primary : Color.gray)
                    )
                    .foregroundColor(.black)
                }
                .disabled(syncCode.count != 6 || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Import from Website")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private func importExercises() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            successMessage = "Sync codes require server storage. For now, use the 'Add Exercise' button in the app to add exercises from the suggested list."
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

// MARK: - Schedule View V4

struct ScheduleViewV4: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var scheduler = WorkoutScheduler.shared
    @ObservedObject var logManager = WorkoutLogManager.shared
    @ObservedObject var themeManager = ThemeManager.shared

    @State private var selectedDate: Date = Date()
    @State private var showingTimePicker = false

    private let calendar = Calendar.current

    private var workoutDates: Set<Date> {
        let logs = logManager.getLogs(for: workoutManager.currentProfile)
        return Set(logs.map { calendar.startOfDay(for: $0.date) })
    }

    var body: some View {
        ZStack {
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Week Calendar Strip
                    WeekCalendarViewV4(
                        selectedDate: $selectedDate,
                        workoutDates: workoutDates,
                        scheduledDate: scheduler.nextWorkoutDate
                    ) { date in
                        let today = calendar.startOfDay(for: Date())
                        if calendar.startOfDay(for: date) >= today {
                            scheduler.setNextWorkoutDate(date, profile: workoutManager.currentProfile)
                        }
                    }

                    // Next Workout Card
                    SchedulerCardV4(
                        nextDate: scheduler.nextWorkoutDate,
                        formattedDate: scheduler.formattedNextWorkoutDate(),
                        daysUntil: scheduler.daysUntilNextWorkout()
                    )

                    // Notification Settings
                    notificationSection

                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheetV4(preferredTime: $scheduler.preferredWorkoutTime)
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                // Toggle
                HStack {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.primary)

                    Text("Workout Reminders")
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: $scheduler.notificationsEnabled)
                        .labelsHidden()
                        .tint(themeManager.primary)
                        .onChange(of: scheduler.notificationsEnabled) { _, enabled in
                            if enabled {
                                scheduler.requestNotificationPermission { granted in
                                    if granted, let nextDate = scheduler.nextWorkoutDate {
                                        scheduler.scheduleWorkoutNotification(for: nextDate, profile: workoutManager.currentProfile)
                                    }
                                }
                            } else {
                                scheduler.cancelAllNotifications(for: workoutManager.currentProfile)
                            }
                        }
                }
                .padding(16)

                if scheduler.notificationsEnabled {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    Button(action: { showingTimePicker = true }) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.primary)

                            Text("Reminder Time")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Spacer()

                            Text(formattedTime)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                    }
                }
            }
            .background {
                GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
            }
            .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                QuickActionButtonV4(icon: "arrow.clockwise", title: "Reschedule", color: .blue) {
                    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                        scheduler.setNextWorkoutDate(tomorrow, profile: workoutManager.currentProfile)
                    }
                }

                QuickActionButtonV4(icon: "calendar.badge.plus", title: "Add Rest", color: .green) {
                    if let nextDate = scheduler.nextWorkoutDate,
                       let newDate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                        scheduler.setNextWorkoutDate(newDate, profile: workoutManager.currentProfile)
                    }
                }

                QuickActionButtonV4(icon: "bolt.fill", title: "Today", color: themeManager.primary) {
                    scheduler.setNextWorkoutDate(Date(), profile: workoutManager.currentProfile)
                }
            }
        }
    }

    var formattedTime: String {
        let hour = scheduler.preferredWorkoutTime.hour ?? 9
        let minute = scheduler.preferredWorkoutTime.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "9:00 AM"
    }
}

// MARK: - Week Calendar View V4

struct WeekCalendarViewV4: View {
    @Binding var selectedDate: Date
    let workoutDates: Set<Date>
    let scheduledDate: Date?
    let onDateTap: (Date) -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    private let calendar = Calendar.current
    @State private var weekOffset: Int = 0

    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Navigation
            HStack {
                Button(action: { weekOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.primary)
                }

                Spacer()

                Text(weekTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { weekOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.primary)
                }
            }

            // Days
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    DayCellV4(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        hasWorkout: workoutDates.contains(calendar.startOfDay(for: date)),
                        isScheduled: scheduledDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        selectedDate = date
                        onDateTap(date)
                    }
                }
            }
        }
        .padding(16)
        .background {
            GlassBackground(tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: .black.opacity(themeManager.glassShadowOpacity * 0.3), radius: 8, y: 4)
    }

    var weekTitle: String {
        if weekOffset == 0 { return "This Week" }
        else if weekOffset == 1 { return "Next Week" }
        else if weekOffset == -1 { return "Last Week" }
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            if let first = weekDays.first, let last = weekDays.last {
                return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
            }
            return ""
        }
    }
}

// MARK: - Day Cell V4

struct DayCellV4: View {
    let date: Date
    let isToday: Bool
    let hasWorkout: Bool
    let isScheduled: Bool
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? themeManager.primary : .white)

                Circle()
                    .fill(indicatorColor)
                    .frame(width: 6, height: 6)
                    .opacity(hasWorkout || isScheduled ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? themeManager.primary.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1)).uppercased()
    }

    var indicatorColor: Color {
        if isScheduled && !hasWorkout { return themeManager.primary }
        else if hasWorkout { return .green }
        return .clear
    }
}

// MARK: - Scheduler Card V4

struct SchedulerCardV4: View {
    let nextDate: Date?
    let formattedDate: String
    let daysUntil: Int
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT WORKOUT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)

                    Text(formattedDate)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Countdown Circle
                ZStack {
                    Circle()
                        .stroke(themeManager.primary.opacity(0.2), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(themeManager.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(daysUntil)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeManager.primary)
                        Text("days")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 60, height: 60)
            }

            if daysUntil == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(themeManager.primary)
                    Text("Today is workout day!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(themeManager.primary.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background {
            GlassBackground(isActive: daysUntil == 0, tintColor: themeManager.primary, cornerRadius: 16)
        }
        .shadow(color: themeManager.primary.opacity(themeManager.glassShadowOpacity * 0.3), radius: 10, y: 5)
    }

    var progressValue: CGFloat {
        let maxDays: CGFloat = 7
        return CGFloat(max(0, min(daysUntil, 7))) / maxDays
    }
}

// MARK: - Quick Action Button V4

struct QuickActionButtonV4: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                GlassBackground(tintColor: color, cornerRadius: 12)
            }
            .shadow(color: color.opacity(ThemeManager.shared.glassShadowOpacity * 0.2), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Picker Sheet V4

struct TimePickerSheetV4: View {
    @Binding var preferredTime: DateComponents
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedTime: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color(hex: "0D0D0F")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)

                    Spacer()

                    Text("Reminder Time")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Save") {
                        preferredTime.hour = calendar.component(.hour, from: selectedTime)
                        preferredTime.minute = calendar.component(.minute, from: selectedTime)
                        dismiss()
                    }
                    .foregroundColor(themeManager.primary)
                    .fontWeight(.semibold)
                }
                .padding()

                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                Spacer()
            }
        }
        .onAppear {
            var components = DateComponents()
            components.hour = preferredTime.hour ?? 9
            components.minute = preferredTime.minute ?? 0
            if let date = calendar.date(from: components) {
                selectedTime = date
            }
        }
    }
}

// MARK: - Glass Preset Button
struct GlassPresetButton: View {
    let title: String
    let value: Double
    let current: Double
    let action: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    private var isSelected: Bool {
        abs(current - value) < 0.05
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.primary)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                                .opacity(value)
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
        .preferredColorScheme(.dark)
}
