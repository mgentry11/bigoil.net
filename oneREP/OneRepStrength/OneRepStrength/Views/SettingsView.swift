//
//  SettingsView.swift
//  OneRepStrength
//
//  App settings including profile name editing and phase timing
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var editingName: String = ""
    @State private var prepDuration: Double = 5
    @State private var positiveDuration: Double = 10
    @State private var holdDuration: Double = 10
    @State private var negativeDuration: Double = 10
    @State private var restDuration: Double = 90
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: DS.xl) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, DS.l)
                    .padding(.top, DS.s)
                    
                    // Profile Settings
                    VStack(alignment: .leading, spacing: DS.m) {
                        Text("Profile Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: DS.m) {
                            ForEach(0..<profileManager.profiles.count, id: \.self) { index in
                                VStack(spacing: DS.s) {
                                    TextField("Name", text: Binding(
                                        get: { profileManager.profiles[index].name },
                                        set: { profileManager.profiles[index].name = $0 }
                                    ))
                                    .font(.system(size: 16, weight: .medium))
                                    .textFieldStyle(.plain)
                                    .padding(DS.m)
                                    .background(
                                        RoundedRectangle(cornerRadius: DSRadius.medium)
                                            .fill(Color.cardBackground)
                                    )
                                    
                                    Text("Profile \(index + 1)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.tertiaryText)
                                }
                            }
                        }
                    }
                    .padding(DS.l)
                    .background(
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                    )
                    .padding(.horizontal, DS.l)
                    
                    // Phase Timing
                    VStack(alignment: .leading, spacing: DS.l) {
                        Text("Phase Timing")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondaryText)
                        
                        TimingRow(title: "Prep", value: $prepDuration, range: 3...15, color: .phasePrep)
                        TimingRow(title: "Positive", value: $positiveDuration, range: 5...30, color: .phasePositive)
                        TimingRow(title: "Hold", value: $holdDuration, range: 0...30, color: .phaseStatic)
                        TimingRow(title: "Negative", value: $negativeDuration, range: 5...30, color: .phaseNegative)
                        
                        Divider()
                        
                        TimingRow(title: "Rest", value: $restDuration, range: 30...180, color: .secondaryText)
                    }
                    .padding(DS.l)
                    .background(
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                    )
                    .padding(.horizontal, DS.l)
                    
                    // Voice Coaching (ElevenLabs)
                    VoiceSettingsCard()
                    
                    // About
                    VStack(alignment: .leading, spacing: DS.m) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.primaryText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondaryText)
                        }
                        .font(.system(size: 15))
                    }
                    .padding(DS.l)
                    .background(
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                    )
                    .padding(.horizontal, DS.l)
                    
                    Spacer(minLength: DS.xxxl)
                }
            }
        }
    }
}

// MARK: - Timing Row
struct TimingRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text("\(Int(value))s")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.secondaryText)
                .frame(width: 44)
            
            Stepper("", value: $value, in: range, step: 5)
                .labelsHidden()
        }
    }
}

// MARK: - Voice Settings Card
struct VoiceSettingsCard: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var elevenLabs = ElevenLabsService.shared
    @State private var showingApiKeyField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.l) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.brandGreen)
                Text("Voice Coaching")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Toggle("", isOn: $audioManager.isEnabled)
                    .labelsHidden()
                    .tint(.brandGreen)
            }
            
            if audioManager.isEnabled {
                // Voice Style Selection
                VStack(alignment: .leading, spacing: DS.s) {
                    Text("Voice Style")
                        .font(.system(size: 13))
                        .foregroundColor(.tertiaryText)
                    
                    HStack(spacing: DS.s) {
                        ForEach(AudioManager.VoiceStyle.allCases, id: \.self) { style in
                            Button(action: { audioManager.voiceStyle = style }) {
                                HStack(spacing: DS.xs) {
                                    if style == .commander {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                    }
                                    Text(style.rawValue)
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(audioManager.voiceStyle == style ? .white : .primaryText)
                                .padding(.horizontal, DS.m)
                                .padding(.vertical, DS.s)
                                .background(
                                    Capsule()
                                        .fill(audioManager.voiceStyle == style ? Color.brandGreen : Color.background)
                                )
                            }
                        }
                    }
                }
                
                // ElevenLabs settings (only shown when ElevenLabs selected)
                if audioManager.voiceStyle == .elevenLabs {
                    Divider()
                    
                    // Voice Selection
                    VStack(alignment: .leading, spacing: DS.s) {
                        Text("ElevenLabs Voice")
                            .font(.system(size: 13))
                            .foregroundColor(.tertiaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DS.s) {
                                ForEach(ElevenLabsService.voices, id: \.id) { voice in
                                    Button(action: { elevenLabs.voiceId = voice.id }) {
                                        Text(voice.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(elevenLabs.voiceId == voice.id ? .white : .secondaryText)
                                            .padding(.horizontal, DS.s)
                                            .padding(.vertical, DS.xs)
                                            .background(
                                                Capsule()
                                                    .fill(elevenLabs.voiceId == voice.id ? Color.brandPurple : Color.background)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // API Key
                    Button(action: { showingApiKeyField.toggle() }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.secondaryText)
                            Text(elevenLabs.apiKey.isEmpty ? "Add API Key" : "API Key ✓")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryText)
                            Spacer()
                            Image(systemName: showingApiKeyField ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.tertiaryText)
                        }
                    }
                    
                    if showingApiKeyField {
                        SecureField("ElevenLabs API Key", text: $elevenLabs.apiKey)
                            .font(.system(size: 14))
                            .textFieldStyle(.plain)
                            .padding(DS.m)
                            .background(
                                RoundedRectangle(cornerRadius: DSRadius.small)
                                    .fill(Color.background)
                            )
                    }
                }
                
                Divider()
                
                // Test Button
                Button(action: { 
                    audioManager.speak("OneRepStrength voice coaching is ready.")
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Test Voice")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.brandGreen)
                }
            }
        }
        .padding(DS.l)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
        .padding(.horizontal, DS.l)
    }
}

// MARK: - Preview
#Preview {
    SettingsView(profileManager: ProfileManager.shared)
}
