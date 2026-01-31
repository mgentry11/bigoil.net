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

    enum VoiceStyle: String, CaseIterable {
        case commander = "Commander"
        case male = "Male"
        case female = "Female"
        case digital = "Digital"
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isCuePlaying = false
            self.isNumberPlaying = false
            self.onAudioComplete?()
            self.onAudioComplete = nil
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }

    // MARK: - Audio Playback

    /// Main speak method - uses Commander audio if available, otherwise TTS
    func speak(_ text: String, audioFile: String? = nil) {
        if voiceStyle == .commander, let file = audioFile {
            playCommanderAudio(file)
        } else {
            speakText(text)
        }
    }

    /// Play Commander audio file, fallback to TTS
    func playCommanderAudio(_ fileName: String) {
        // Try Audio folder (where shell script copies files)
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Audio") {
            playAudioFile(url)
            return
        }

        // Try root of bundle
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            playAudioFile(url)
            return
        }

        // Try using bundle path directly
        let bundlePath = Bundle.main.bundlePath
        let audioPath = "\(bundlePath)/Audio/\(fileName).mp3"
        let fileURL = URL(fileURLWithPath: audioPath)
        if FileManager.default.fileExists(atPath: audioPath) {
            playAudioFile(fileURL)
            return
        }

        speakText(convertFileNameToText(fileName))
    }

    private func playAudioFile(_ url: URL) {
        // Stop any currently playing audio first
        audioPlayer?.stop()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch { }
    }

    /// Play a phase cue and call completion when done
    func playCue(_ text: String, audioFile: String, completion: @escaping () -> Void) {
        isCuePlaying = true

        if voiceStyle == .commander {
            // Try to play audio file
            let bundlePath = Bundle.main.bundlePath
            let audioPath = "\(bundlePath)/Audio/\(audioFile).mp3"

            if FileManager.default.fileExists(atPath: audioPath) {
                let url = URL(fileURLWithPath: audioPath)
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.delegate = self
                    audioPlayer?.play()
                    isPlaying = true

                    // Use audio duration to schedule completion
                    let duration = audioPlayer?.duration ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                        self.isCuePlaying = false
                        completion()
                    }
                    return
                } catch { }
            }
        }

        // Fallback to TTS - estimate duration and call completion
        speakText(text)
        // TTS doesn't have delegate, so estimate ~2 seconds for cue
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isCuePlaying = false
            completion()
        }
    }

    func playAudio(_ fileName: String) {
        guard voiceStyle == .commander else {
            // Use TTS for other voice styles
            speakText(convertFileNameToText(fileName))
            return
        }

        playCommanderAudio(fileName)
    }

    // Convert audio file names to spoken text
    private func convertFileNameToText(_ fileName: String) -> String {
        // Handle number files
        if fileName.hasPrefix("num_") {
            return fileName.replacingOccurrences(of: "num_", with: "")
        }

        // Handle phase announcements
        let phaseMap: [String: String] = [
            "phase_get_ready": "Get ready",
            "phase_position": "Position",
            "phase_eccentric": "Eccentric phase",
            "phase_concentric": "Concentric phase",
            "phase_final_eccentric": "Final eccentric",
            "phase_complete": "Complete",
            "phase_rest": "Rest"
        ]

        if let text = phaseMap[fileName] {
            return text
        }

        // Handle exercise names - convert snake_case to Title Case
        return fileName
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    func playNumber(_ number: Int) {
        guard number >= 1 && number <= 60 else { return }
        playAudio("num_\(number)")
    }

    @discardableResult
    func playCountdownNumber(_ number: Int) -> Bool {
        guard number >= 1 && number <= 60 else { return false }
        
        guard !isNumberPlaying else { return false }

        numberPlaybackWorkItem?.cancel()
        
        isNumberPlaying = true

        if voiceStyle == .commander {
            let fileName = "num_\(number)"
            let bundlePath = Bundle.main.bundlePath
            let audioPath = "\(bundlePath)/Audio/\(fileName).mp3"

            if FileManager.default.fileExists(atPath: audioPath) {
                let url = URL(fileURLWithPath: audioPath)
                playAudioFile(url)

                let lockoutDuration: Double = number <= 5 ? 0.9 : 0.7
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isNumberPlaying = false
                }
                numberPlaybackWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + lockoutDuration, execute: workItem)
                return true
            }
        }

        let utterance = AVSpeechUtterance(string: "\(number)")
        utterance.rate = 0.5
        utterance.volume = 1.0
        if let voice = getVoice() {
            utterance.voice = voice
        }
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)

        let lockoutDuration: Double = number <= 5 ? 0.9 : 0.6
        let workItem = DispatchWorkItem { [weak self] in
            self?.isNumberPlaying = false
        }
        numberPlaybackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + lockoutDuration, execute: workItem)
        return true
    }

    func playPhaseAnnouncement(_ phase: TimerPhase) {
        playAudio(phase.audioFileName)
    }

    func playExerciseAnnouncement(_ exercise: Exercise) {
        playAudio(exercise.audioFileName)
    }

    func queueAudio(_ fileNames: [String]) {
        audioQueue.append(contentsOf: fileNames)
        processQueue()
    }

    private func processQueue() {
        guard !isProcessingQueue, !audioQueue.isEmpty else { return }
        isProcessingQueue = true

        let fileName = audioQueue.removeFirst()
        playAudio(fileName)

        // Simple delay before next audio
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isProcessingQueue = false
            self?.processQueue()
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        isCuePlaying = false
        isNumberPlaying = false
        numberPlaybackWorkItem?.cancel()
        numberPlaybackWorkItem = nil
        audioQueue.removeAll()
        isProcessingQueue = false
    }

    // MARK: - Text-to-Speech (for non-commander voices)
    private let synthesizer = AVSpeechSynthesizer()

    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = voiceStyle == .female ? 1.2 : 0.9
        utterance.volume = 1.0

        if let voice = getVoice() {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    func speakNumber(_ number: Int) {
        speakText(String(number))
    }

    private func getVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        switch voiceStyle {
        case .male:
            return voices.first { $0.language == "en-US" && $0.name.contains("Aaron") }
                ?? AVSpeechSynthesisVoice(language: "en-US")
        case .female:
            return voices.first { $0.language == "en-US" && $0.name.contains("Samantha") }
                ?? AVSpeechSynthesisVoice(language: "en-US")
        case .digital:
            return voices.first { $0.language == "en-US" && $0.quality == .enhanced }
                ?? AVSpeechSynthesisVoice(language: "en-US")
        case .commander:
            return nil // Uses audio files
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
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
