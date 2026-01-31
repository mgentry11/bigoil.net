//
//  ElevenLabsService.swift
//  OneRepStrength
//
//  ElevenLabs Text-to-Speech API integration for voice coaching
//

import Foundation
import AVFoundation

@MainActor
class ElevenLabsService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = ElevenLabsService()
    
    // MARK: - Configuration
    // TODO: Move to secure storage or environment variable
    @Published var apiKey: String = "" {
        didSet { UserDefaults.standard.set(apiKey, forKey: "elevenLabsApiKey") }
    }
    @Published var voiceId: String = "21m00Tcm4TlvDq8ikWAM" // Default: Rachel
    @Published var isEnabled: Bool = true
    @Published var isSpeaking: Bool = false
    
    // Available voices
    static let voices: [(id: String, name: String)] = [
        ("21m00Tcm4TlvDq8ikWAM", "Rachel"),
        ("AZnzlk1XvdvUeBnXmlld", "Domi"),
        ("EXAVITQu4vr4xnSDxMaL", "Bella"),
        ("ErXwobaYiN019PkySvjV", "Antoni"),
        ("MF3mGyEYCl7XYWbV9V6O", "Elli"),
        ("TxGEqnHWrfWFTfGW9XjX", "Josh"),
        ("VR6AewLTigWG4xSOukaG", "Arnold"),
        ("pNInz6obpgDQGcFmaJgB", "Adam"),
        ("yoZ06aMxZJJ28mfd3POQ", "Sam"),
    ]
    
    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [Data] = []
    private var isProcessingQueue = false
    private let session = URLSession.shared
    
    override init() {
        super.init()
        apiKey = UserDefaults.standard.string(forKey: "elevenLabsApiKey") ?? ""
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Text-to-Speech API
    
    /// Speak text using ElevenLabs API
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        guard isEnabled, !apiKey.isEmpty else {
            completion?()
            return
        }
        
        Task {
            do {
                let audioData = try await fetchSpeech(text: text)
                await playAudio(data: audioData, completion: completion)
            } catch {
                print("ElevenLabs error: \(error)")
                completion?()
            }
        }
    }
    
    /// Fetch speech audio from ElevenLabs API
    private func fetchSpeech(text: String) async throws -> Data {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.5,
                "use_speaker_boost": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ElevenLabsError.apiError
        }
        
        return data
    }
    
    /// Play audio data
    private func playAudio(data: Data, completion: (() -> Void)?) async {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            isSpeaking = true
            audioPlayer?.play()
            
            // Wait for playback to complete
            while audioPlayer?.isPlaying == true {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            isSpeaking = false
            completion?()
        } catch {
            print("Audio playback error: \(error)")
            isSpeaking = false
            completion?()
        }
    }
    
    // MARK: - Workout Phrases
    
    /// Speak phase announcement
    func announcePhase(_ phase: TimerPhase) {
        let phrases: [TimerPhase: String] = [
            .prep: "Get ready. Position yourself on the machine.",
            .positive: "Now! Slowly push up. Control the movement.",
            .hold: "Hold it at the top. Squeeze the muscle.",
            .negative: "Lower it down slowly. Feel the tension.",
            .complete: "Great work! Log your weight.",
            .rest: "Rest and recover. Take deep breaths."
        ]
        
        if let phrase = phrases[phase] {
            speak(phrase)
        }
    }
    
    /// Speak exercise name
    func announceExercise(_ exercise: Exercise) {
        speak("Next exercise: \(exercise.name)")
    }
    
    /// Speak countdown number
    func announceNumber(_ number: Int) {
        guard number <= 5, number >= 1 else { return }
        speak("\(number)")
    }
    
    /// Speak workout start
    func announceWorkoutStart() {
        speak("Let's get started. Focus and intensity.")
    }
    
    /// Speak workout complete
    func announceWorkoutComplete() {
        speak("Workout complete! Great session. You crushed it.")
    }
    
    /// Speak PR celebration
    func announcePR(exercise: String) {
        speak("New personal record on \(exercise)! Incredible work!")
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    // MARK: - Control
    
    func stop() {
        audioPlayer?.stop()
        isSpeaking = false
    }
}

// MARK: - Errors
enum ElevenLabsError: Error {
    case apiError
    case invalidResponse
}
