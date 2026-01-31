//
//  VoiceCoach.swift
//  HITCoachPro
//

import AVFoundation
import Foundation

class VoiceCoach: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    private var currentVoice: AVSpeechSynthesisVoice?
    private var coachingMode: String = "phaseOnly"

    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func configure(voiceGender: String, coachingMode: String) {
        self.coachingMode = coachingMode
        self.currentVoice = selectVoice(for: voiceGender)
    }

    private func selectVoice(for gender: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        switch gender {
        case "male":
            return voices.first(where: { $0.language == "en-US" && $0.name.contains("Male") }) ??
                   voices.first(where: { $0.language == "en-US" })
        case "female":
            return voices.first(where: { $0.language == "en-US" && $0.name.contains("Female") }) ??
                   voices.first(where: { $0.language.starts(with: "en") })
        case "digital":
            return AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        default:
            return AVSpeechSynthesisVoice(language: "en-US")
        }
    }

    func announcePhase(_ phase: String) {
        speak(phase)
    }

    func announceCountdown(seconds: Int) {
        guard coachingMode != "phaseOnly" else { return }

        let shouldAnnounce: Bool = {
            switch coachingMode {
            case "tenSecondCountdown":
                return seconds <= 10 && seconds > 0
            case "fullCountdown":
                return seconds > 0 && seconds % 5 == 0
            case "encouragement":
                return seconds <= 10 && seconds > 0
            default:
                return false
            }
        }()

        if shouldAnnounce {
            speak("\(seconds)")
        }

        // Add encouragement at specific points
        if coachingMode == "encouragement" {
            if seconds == 45 {
                speak("Halfway there, keep going!")
            } else if seconds == 15 {
                speak("Final push, you've got this!")
            }
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
