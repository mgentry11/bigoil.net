//
//  AudioManager.swift
//  OneRepStrength
//
//  Manages audio playback including Commander voice (pre-recorded) and ElevenLabs TTS
//

import Foundation
import AVFoundation

@MainActor
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    
    enum VoiceStyle: String, CaseIterable {
        case commander = "Commander"
        case elevenLabs = "ElevenLabs"
        case system = "System"
    }
    
    // MARK: - Published Properties
    @Published var voiceStyle: VoiceStyle = .commander {
        didSet { UserDefaults.standard.set(voiceStyle.rawValue, forKey: "voiceStyle") }
    }
    @Published var isEnabled: Bool = true
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private let elevenLabs = ElevenLabsService.shared
    
    override init() {
        super.init()
        if let saved = UserDefaults.standard.string(forKey: "voiceStyle"),
           let style = VoiceStyle(rawValue: saved) {
            voiceStyle = style
        }
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
    
    // MARK: - Speak Methods
    
    /// Main speak method - routes to appropriate voice engine
    func speak(_ text: String, audioFile: String? = nil) {
        guard isEnabled else { return }
        
        switch voiceStyle {
        case .commander:
            if let file = audioFile {
                playCommanderAudio(file)
            } else {
                speakWithTTS(text)
            }
        case .elevenLabs:
            elevenLabs.speak(text)
        case .system:
            speakWithTTS(text)
        }
    }
    
    /// Play commander audio file from bundle
    private func playCommanderAudio(_ fileName: String) {
        // Try to find in bundle
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            playAudioFile(url)
        } else if let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") {
            playAudioFile(url)
        } else {
            // Fallback to TTS if audio file not found
            let text = fileName
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "phase", with: "")
                .replacingOccurrences(of: "ex", with: "")
                .capitalized
            speakWithTTS(text)
        }
    }
    
    private func playAudioFile(_ url: URL) {
        audioPlayer?.stop()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Audio playback error: \(error)")
        }
    }
    
    private func speakWithTTS(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.9
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    // MARK: - Phase Announcements
    
    func announcePhase(_ phase: TimerPhase) {
        let audioFiles: [TimerPhase: String] = [
            .prep: "phase_get_ready",
            .positive: "phase_concentric",
            .hold: "phase_position",
            .negative: "phase_eccentric",
            .complete: "phase_complete",
            .rest: "phase_rest"
        ]
        
        speak(phase.instruction, audioFile: audioFiles[phase])
    }
    
    func announceExercise(_ exercise: Exercise) {
        // Try exercise-specific audio file
        let fileName = "ex_" + exercise.name.lowercased().replacingOccurrences(of: " ", with: "_")
        speak("Next: \(exercise.name)", audioFile: fileName)
    }
    
    func announceNumber(_ number: Int) {
        guard number >= 1 && number <= 10 else { return }
        speak("\(number)", audioFile: "num_\(number)")
    }
    
    func announceWorkoutStart() {
        speak("Let's get started. Focus and intensity.", audioFile: "workout_begin")
    }
    
    func announceWorkoutComplete() {
        speak("Workout complete! Great session.", audioFile: "workout_complete")
    }
    
    func announcePR(exercise: String) {
        speak("New personal record on \(exercise)!", audioFile: "pr_celebration")
    }
    
    // MARK: - Control
    
    func stop() {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
