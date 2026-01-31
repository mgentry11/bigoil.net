import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var audioManager: AudioManager
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddProfile = false
    @State private var newProfileName = ""
    @State private var elevenLabsKey = ""

    var body: some View {
        NavigationView {
            List {
                // MARK: - Profiles
                Section("Profiles") {
                    ForEach(profileManager.profiles) { profile in
                        Button(action: {
                            profileManager.switchProfile(to: profile)
                        }) {
                            HStack {
                                Text(profile.name)
                                    .foregroundColor(ThemeManager.shared.text)
                                Spacer()
                                if profileManager.currentProfile.id == profile.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            profileManager.deleteProfile(profileManager.profiles[index])
                        }
                    }
                    
                    if showingAddProfile {
                        HStack {
                            TextField("New Profile Name", text: $newProfileName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Add") {
                                if !newProfileName.isEmpty {
                                    profileManager.createProfile(name: newProfileName)
                                    newProfileName = ""
                                    showingAddProfile = false
                                }
                            }
                            .foregroundColor(ThemeManager.shared.primary)
                        }
                    } else {
                        Button(action: { showingAddProfile = true }) {
                            Label("Create Profile", systemImage: "plus.circle")
                                .foregroundColor(ThemeManager.shared.primary)
                        }
                    }
                }
                .listRowBackground(ThemeManager.shared.card)
                
                // MARK: - Voice Options
                Section("Voice Options") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Voice Style")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Picker("Voice", selection: $audioManager.voiceStyle) {
                            Text("Commander (Local)").tag(AudioManager.VoiceStyle.commander)
                            Text("Male (Siri)").tag(AudioManager.VoiceStyle.male)
                            Text("Female (Siri)").tag(AudioManager.VoiceStyle.female)
                            Text("Digital (Siri)").tag(AudioManager.VoiceStyle.digital)
                            Text("ElevenLabs (AI)").tag(AudioManager.VoiceStyle.elevenLabs)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if audioManager.voiceStyle == .elevenLabs {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Key (Optional)")
                                    .font(.caption)
                                SecureField("sk_...", text: $elevenLabsKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: elevenLabsKey) { newValue in
                                        if !newValue.isEmpty {
                                            SecureStorage.shared.save(data: newValue.data(using: .utf8)!, forKey: "elevenLabsAPIKey")
                                        }
                                    }
                                Text("Using 'Commander' voice from your account if found.")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(ThemeManager.shared.card)

                // MARK: - Color Theme
                Section("Color Theme") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(ThemeManager.shared.card)
                }

                // Phase Timing
                Section("Phase Timing") {
                    PhaseTimingStepper(
                        title: "Prep",
                        value: $workoutManager.phaseSettings.prepDuration,
                        range: 0...30
                    )
                    PhaseTimingStepper(
                        title: "Positioning",
                        value: $workoutManager.phaseSettings.positioningDuration,
                        range: 0...15
                    )
                    PhaseTimingStepper(
                        title: "Eccentric",
                        value: $workoutManager.phaseSettings.eccentricDuration,
                        range: 10...60
                    )
                    PhaseTimingStepper(
                        title: "Concentric",
                        value: $workoutManager.phaseSettings.concentricDuration,
                        range: 10...60
                    )
                    PhaseTimingStepper(
                        title: "Final Eccentric",
                        value: $workoutManager.phaseSettings.finalEccentricDuration,
                        range: 20...90
                    )
                    PhaseTimingStepper(
                        title: "Rest",
                        value: $workoutManager.phaseSettings.restDuration,
                        range: 30...180
                    )
                    
                    Button(action: {
                        workoutManager.phaseSettings = PhaseSettings()
                        UserDefaults.standard.removeObject(forKey: "phaseSettings")
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                            Text("Reset to Defaults")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .listRowBackground(ThemeManager.shared.card)

                // Sync Exercises
                Section("Sync Exercises") {
                    NavigationLink(destination: SyncCodeView()) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(ThemeManager.shared.primary)
                            Text("Import from Website")
                        }
                    }
                    .listRowBackground(ThemeManager.shared.card)

                    if let exerciseLibraryURL = URL(string: "https://onerepstrength.com/exercises.html") {
                        Link(destination: exerciseLibraryURL) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(ThemeManager.shared.primary)
                                Text("Browse Exercise Library")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(ThemeManager.shared.card)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(ThemeManager.shared.card)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeManager.shared.background)
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Voice Button
struct VoiceButton: View {
    let style: AudioManager.VoiceStyle
    let currentStyle: AudioManager.VoiceStyle
    let action: () -> Void

    var label: String {
        switch style {
        case .male: return "M"
        case .female: return "F"
        case .digital: return "D"
        case .commander: return "C"
        }
    }

    var isSelected: Bool {
        style == currentStyle
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .frame(width: 44, height: 44)
                .background(isSelected ? ThemeManager.shared.primary : Color(white: 0.2))
                .cornerRadius(10)
        }
    }
}

// MARK: - Phase Timing Stepper
struct PhaseTimingStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)s")
                .foregroundColor(.gray)
                .frame(width: 50)

            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}

// MARK: - Sync Code View
struct SyncCodeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var syncCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(ThemeManager.shared.primary)

                Text("Import Exercises")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the 6-character code from the website to import your selected exercises.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Code Input
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let char = index < syncCode.count ? String(syncCode[syncCode.index(syncCode.startIndex, offsetBy: index)]) : ""
                    Text(char)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .frame(width: 44, height: 56)
                        .background(ThemeManager.shared.card)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(index < syncCode.count ? ThemeManager.shared.primary : Color(white: 0.3), lineWidth: 2)
                        )
                }
            }

            // Hidden text field for input
            TextField("", text: $syncCode)
                .keyboardType(.asciiCapable)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focused($isInputFocused)
                .onChange(of: syncCode) { oldValue, newValue in
                    // Limit to 6 characters, uppercase only
                    let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                    if filtered != syncCode {
                        syncCode = filtered
                    }
                }

            // Tap to edit hint
            Button(action: { isInputFocused = true }) {
                Text("Tap to enter code")
                    .font(.caption)
                    .foregroundColor(ThemeManager.shared.primary)
            }

            // Error/Success messages
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if let success = successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }

            Spacer()

            // Import button
            Button(action: importExercises) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("Import Exercises")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(syncCode.count == 6 ? ThemeManager.shared.primary : Color.gray)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(syncCode.count != 6 || isLoading)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(ThemeManager.shared.background)
        .navigationTitle("Import from Website")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    @FocusState private var isInputFocused: Bool

    private func importExercises() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        // For now, show instructions since we need server-side storage for real sync
        // In a production app, this would fetch from a backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false

            // Simulated response - in production this would fetch from server
            // For now, show a message about manual sync
            successMessage = "Sync codes require server storage. For now, use the 'Add Exercise' button in the app to add exercises from the suggested list."

            // Clear code after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
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
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeManager.shared.text)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(ThemeManager.shared.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? theme.primaryColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(WorkoutManager())
        .environmentObject(AudioManager())
}
