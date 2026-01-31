//
//  VoiceCommandButton.swift
//  OneRepStrength
//
//  A floating button for activating voice commands during workouts.
//

import SwiftUI

struct VoiceCommandButton: View {
    @ObservedObject var voiceService = VoiceCommandService.shared
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        if voiceService.isVoiceControlEnabled {
            Button(action: {
                voiceService.toggleListening()
            }) {
                ZStack {
                    // Listening pulse animation
                    if voiceService.isListening {
                        Circle()
                            .fill(themeManager.primary.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .scaleEffect(voiceService.isListening ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: voiceService.isListening
                            )
                    }

                    Circle()
                        .fill(voiceService.isListening ? themeManager.primary : Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .shadow(color: themeManager.primary.opacity(voiceService.isListening ? 0.6 : 0.2), radius: 12, y: 4)

                    VStack(spacing: 2) {
                        Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(voiceService.isListening ? .black : .white)

                        if voiceService.isListening {
                            Text("Listening...")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                // Show transcribed text when listening
                if voiceService.isListening && !voiceService.transcribedText.isEmpty {
                    Text(voiceService.transcribedText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .offset(y: -70)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                }
            }
        } else {
            // Show regular menu button when voice control is disabled
            Button(action: {
                // Menu action placeholder
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(themeManager.primary)
                            .shadow(color: themeManager.primary.opacity(0.4), radius: 12, y: 4)
                    )
            }
        }
    }
}

// MARK: - Compact Voice Button (for status bars)
struct CompactVoiceButton: View {
    @ObservedObject var voiceService = VoiceCommandService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    var size: CGFloat = 32

    var body: some View {
        if voiceService.isVoiceControlEnabled {
            Button(action: {
                voiceService.toggleListening()
            }) {
                ZStack {
                    if voiceService.isListening {
                        Circle()
                            .fill(themeManager.primary.opacity(0.3))
                            .frame(width: size + 8, height: size + 8)
                            .scaleEffect(voiceService.isListening ? 1.15 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true),
                                value: voiceService.isListening
                            )
                    }

                    Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                        .font(.system(size: size * 0.45, weight: .semibold))
                        .foregroundColor(voiceService.isListening ? themeManager.primary : .white)
                        .frame(width: size, height: size)
                        .background(voiceService.isListening ? themeManager.primary.opacity(0.3) : Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VoiceCommandButton()
    }
}
