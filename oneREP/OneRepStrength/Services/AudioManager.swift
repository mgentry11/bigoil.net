import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published Properties
    @Published var voiceStyle: VoiceStyle = .commander
    @Published var isPlaying: Bool = false
    @Published var isCuePlaying: Bool = false
    @Published var isNumberPlaying: Bool = false

    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [String] = []
    private var isProcessingQueue = false
    private var onAudioComplete: (() -> Void)?
    private var numberPlaybackWorkItem: DispatchWorkItem?
    private let synthesizer = AVSpeechSynthesizer()

    enum VoiceStyle: String, CaseIterable, Codable {
        case commander = "Commander"
        case male = "Male"
        case female = "Female"
        case digital = "Digital"
        case elevenLabs = "AI Voice (ElevenLabs)"
    }

    // ...

    func speakText(_ text: String) {
        if voiceStyle == .elevenLabs {
            ElevenLabsService.shared.generateAudio(text: text) { [weak self] result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self?.playAudioFile(url)
                    }
                case .failure(let error):
                    print("ElevenLabs playback failed: \(error)")
                    // Fallback to TTS? Or just fail silently/log.
                }
            }
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voiceStyle == .commander ? 0.52 : 0.5
        
        // Adjust pitch
        switch voiceStyle {
        case .female:
            utterance.pitchMultiplier = 1.2
        case .commander:
            utterance.pitchMultiplier = 0.85 // Deep, commanding voice
        default:
            utterance.pitchMultiplier = 1.0 // Normalized
        }
        
        utterance.volume = 1.0

        if let voice = getVoice() {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    // ...

    private func getVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        let englishVoices = voices.filter { $0.language.starts(with: "en") }
        
        switch voiceStyle {
        case .male, .commander:
            // Try specific high-quality male voices
            if let specific = englishVoices.first(where: { $0.name.contains("Aaron") || $0.name.contains("Fred") || $0.name.contains("Alex") }) {
                return specific
            }
            // Fallback to any male voice (if identifiable) or just the first US voice
            return englishVoices.first(where: { $0.language == "en-US" }) ?? AVSpeechSynthesisVoice(language: "en-US")
            
        case .female:
            if let specific = englishVoices.first(where: { $0.name.contains("Samantha") || $0.name.contains("Karen") || $0.name.contains("Tessa") }) {
                return specific
            }
            return englishVoices.first(where: { $0.language == "en-US" }) ?? AVSpeechSynthesisVoice(language: "en-US")
            
        case .digital:
            return englishVoices.first(where: { $0.quality == .enhanced }) ?? englishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
            
        case .elevenLabs:
            return nil
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func stopAudio() {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isCuePlaying = false
        isNumberPlaying = false
        numberPlaybackWorkItem?.cancel()
    }

    func playAudioFile(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio file: \(error)")
        }
    }

    func speak(_ text: String, audioFile: String? = nil) {
        print("[AudioManager] speak called - text: '\(text)', audioFile: \(audioFile ?? "nil"), voiceStyle: \(voiceStyle)")
        
        if let audioFile = audioFile, voiceStyle == .commander {
            print("[AudioManager] Commander mode - looking up mapping for: '\(audioFile)'")
            
            // Check mapping first
            if let mappedFile = SoundMappingManager.shared.getFilename(for: audioFile) {
                print("[AudioManager] Found mapping: '\(audioFile)' -> '\(mappedFile)'")
                
                // Try playing mapped file (check flat and Audio subdir)
                if playAudioResource(mappedFile) {
                    print("[AudioManager] Successfully playing mapped file: '\(mappedFile)'")
                    return
                } else {
                    print("[AudioManager] FAILED to find mapped file in bundle: '\(mappedFile)'")
                }
            } else {
                print("[AudioManager] No mapping found for: '\(audioFile)'")
            }
            
            // Fallback to direct name (legacy/default)
            print("[AudioManager] Trying direct filename: '\(audioFile)'")
            if playAudioResource(audioFile) {
                print("[AudioManager] Successfully playing direct file: '\(audioFile)'")
                return
            } else {
                print("[AudioManager] FAILED direct lookup, falling back to TTS")
            }
        }
        speakText(text)
    }
    
    // Helper to find and play resource
    private func playAudioResource(_ filename: String) -> Bool {
        print("[AudioManager] playAudioResource checking for: '\(filename).mp3'")
        
        if let path = Bundle.main.path(forResource: filename, ofType: "mp3") {
            print("[AudioManager] Found at root: \(path)")
            playAudioFile(URL(fileURLWithPath: path))
            return true
        }
        if let path = Bundle.main.path(forResource: filename, ofType: "mp3", inDirectory: "Audio") {
            print("[AudioManager] Found in Audio subdir: \(path)")
            playAudioFile(URL(fileURLWithPath: path))
            return true
        }
        print("[AudioManager] File NOT found in bundle: '\(filename).mp3'")
        return false
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.onAudioComplete?()
            self.onAudioComplete = nil
        }
    }

    private func convertFileNameToText(_ filename: String) -> String {
        let parts = filename.split(separator: "_")
        guard parts.count > 1 else { return filename.capitalized }
        return parts.dropFirst().joined(separator: " ").capitalized
    }

    func playCue(_ text: String, audioFile: String, completion: (() -> Void)? = nil) {
        speak(text, audioFile: audioFile)
        // Call completion after a delay to simulate audio completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion?()
        }
    }

    func playCountdownNumber(_ number: Int) {
        // Use mapped audio file for Commander voice
        let audioKey = "count_\(number)"
        speak("\(number)", audioFile: audioKey)
    }
}

// MARK: - Audio File Names
extension AudioManager {
    struct AudioFiles {
        // Phases
        static let getReady = "phase_get_ready"
        static let position = "phase_position"
        static let eccentric = "phase_eccentric"
        static let concentric = "phase_concentric"
        static let finalEccentric = "phase_final_eccentric"
        static let complete = "phase_complete"
        static let rest = "phase_rest"

        // Encouragement / Motivational
        static let encouragement = [
            "enc_doing_great", "enc_keep_going", "enc_almost_there",
            "enc_stay_strong", "enc_push_through", "enc_you_got_this",
            "enc_excellent_form", "enc_perfect", "enc_fantastic",
            "enc_thats_it", "enc_well_done", "enc_great_work",
            "enc_one_more", "enc_strong_finish"
        ]

        // Eccentric cues - slow controlled lowering
        static let eccentricCues = [
            "ecc_lower_slowly", "ecc_control_weight", "ecc_nice_slow",
            "ecc_keep_tension", "ecc_feel_stretch", "ecc_resist", "ecc_smooth"
        ]

        // Concentric cues - powerful lifting
        static let concentricCues = [
            "con_push_now", "con_drive_up", "con_power",
            "con_squeeze", "con_contract", "con_strong_push", "con_keep_pushing"
        ]

        // Final eccentric cues - push to failure
        static let finalCues = [
            "final_all_way", "final_fight", "final_dont_give_up",
            "final_max_tension", "final_last_push", "final_slow",
            "final_negative", "final_control"
        ]

        // Positioning/Setup cues
        static let positioningCues = [
            "cue_get_position", "cue_grip", "cue_posture",
            "cue_control", "cue_starting_weight"
        ]

        // Rest cues
        static let restStarting = "rest_starting"
        static let restBreathe = "rest_breathe"
        static let restRecover = "rest_recover"
        static let restGetReady = "rest_get_ready"
        static let restNextComing = "rest_next_coming"
        static let restComplete = "rest_complete"
        static let rest15Sec = "rest_15_sec"
        static let rest30Sec = "rest_30_sec"

        // Time cues
        static let halfway = "time_halfway"
        static let almostThere = "time_almost"
        static let time5Sec = "time_5_sec"
        static let time10Sec = "time_10_sec"
        static let time20Sec = "time_20_sec"
        static let time30Sec = "time_30_sec"

        // Transition cues
        static let transMoving = "trans_moving"
        static let transNext = "trans_next"
        static let transPrepare = "trans_prepare"

        // Workout cues
        static let workoutBegin = "workout_begin"
        static let workoutStarting = "workout_starting"
        static let workoutComplete = "workout_complete"
        static let workoutCrushed = "workout_crushed"
        static let workoutGreatSession = "workout_great_session"
        static let workoutSeeYou = "workout_see_you"
    }

    // MARK: - Random Cue Methods
    func playRandomEccentricCue() {
        let cue = AudioFiles.eccentricCues.randomElement() ?? "ecc_lower_slowly"
        speak(convertFileNameToText(cue), audioFile: cue)
    }

    func playRandomConcentricCue() {
        let cue = AudioFiles.concentricCues.randomElement() ?? "con_push_now"
        speak(convertFileNameToText(cue), audioFile: cue)
    }

    func playRandomFinalCue() {
        let cue = AudioFiles.finalCues.randomElement() ?? "final_all_way"
        speak(convertFileNameToText(cue), audioFile: cue)
    }

    func playHalfwayCue() {
        speak("Halfway there!", audioFile: AudioFiles.halfway)
    }

    func playRandomEncouragement() {
        let cue = AudioFiles.encouragement.randomElement() ?? "enc_great_work"
        speak(convertFileNameToText(cue), audioFile: cue)
    }

    func playRandomPositioningCue() {
        let cue = AudioFiles.positioningCues.randomElement() ?? "cue_get_position"
        speak(convertFileNameToText(cue), audioFile: cue)
    }

    // MARK: - Rest Cues
    func playRestStarting() {
        speak("Rest starting", audioFile: AudioFiles.restStarting)
    }

    func playRestBreathe() {
        speak("Breathe and recover", audioFile: AudioFiles.restBreathe)
    }

    func playRestGetReady() {
        speak("Get ready for the next exercise", audioFile: AudioFiles.restGetReady)
    }

    func playRestNextComing() {
        speak("Next exercise coming up", audioFile: AudioFiles.restNextComing)
    }

    func playRestComplete() {
        speak("Rest complete", audioFile: AudioFiles.restComplete)
    }

    // MARK: - Time Cues
    func play10SecondWarning() {
        speak("10 seconds! Give it everything!", audioFile: AudioFiles.time10Sec)
    }

    func play5SecondWarning() {
        speak("5 seconds", audioFile: AudioFiles.time5Sec)
    }

    func playAlmostThere() {
        speak("Almost there!", audioFile: AudioFiles.almostThere)
    }

    // MARK: - Workout Cues
    func playWorkoutBegin() {
        speak("Workout begin!", audioFile: AudioFiles.workoutBegin)
    }

    func playWorkoutComplete() {
        speak("Workout complete! Amazing job!", audioFile: AudioFiles.workoutComplete)
    }

    func playWorkoutCrushed() {
        speak("You crushed it!", audioFile: AudioFiles.workoutCrushed)
    }

    func playWorkoutGreatSession() {
        speak("Great session!", audioFile: AudioFiles.workoutGreatSession)
    }

    // MARK: - Transition Cues
    func playTransitionNext() {
        speak("Moving to next exercise", audioFile: AudioFiles.transNext)
    }

    func playTransitionPrepare() {
        speak("Prepare for the next exercise", audioFile: AudioFiles.transPrepare)
    }
}
