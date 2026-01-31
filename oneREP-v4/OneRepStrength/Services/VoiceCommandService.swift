//
//  VoiceCommandService.swift
//  OneRepStrength
//
//  Voice command service for hands-free workout control.
//  Uses iOS Speech Recognition as primary with Whisper API fallback for improved accuracy.
//

import Foundation
import Speech
import AVFoundation
import Combine
import MediaPlayer
import os.log

// MARK: - Voice Command Types
enum VoiceCommand: Equatable {
    case startExercise(String)      // "Start leg press"
    case nextExercise               // "Next" or "Next exercise"
    case skipPhase                  // "Skip"
    case pause                      // "Pause"
    case resume                     // "Resume" or "Continue"
    case stop                       // "Stop"
    case done                       // "Done" or "Finished"
    case skipRest                   // "Skip rest"
    case anotherSet                 // "Another set" or "One more"
    case logWeight(Int)             // "Log 150" or "150 pounds"
    case unknown(String)            // Unrecognized command
}

// MARK: - Recognition Confidence
struct RecognitionResult {
    let text: String
    let confidence: Float  // 0.0 to 1.0
    let isFinal: Bool
}

// MARK: - Voice Command Service
class VoiceCommandService: NSObject, ObservableObject {
    static let shared = VoiceCommandService()
    
    // MARK: - Logging
    private let log = OSLog(subsystem: "com.onerepstrength.app", category: "VoiceCommand")

    // MARK: - Published Properties
    @Published var isListening: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var lastCommand: VoiceCommand?
    @Published var transcribedText: String = ""
    @Published var errorMessage: String?
    @Published var isProcessingWithWhisper: Bool = false
    @Published var useWhisperFallback: Bool = true {
        didSet {
            UserDefaults.standard.set(useWhisperFallback, forKey: "useWhisperFallback")
        }
    }
    @Published var isVoiceControlEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isVoiceControlEnabled, forKey: "voiceControlEnabled")
            if isVoiceControlEnabled {
                setupRemoteCommandCenter()
            } else {
                removeRemoteCommandCenter()
                stopContinuousListening()
            }
        }
    }

    // Continuous listening mode - listens for wake word "Hey One Rep" or "One Rep"
    @Published var isContinuousListeningEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isContinuousListeningEnabled, forKey: "continuousListeningEnabled")
            if isContinuousListeningEnabled && isVoiceControlEnabled {
                startContinuousListening()
            } else {
                stopContinuousListening()
            }
        }
    }
    @Published var isContinuouslyListening: Bool = false
    @Published var wakeWordDetected: Bool = false

    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Continuous listening
    private var continuousRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var continuousRecognitionTask: SFSpeechRecognitionTask?
    private var continuousAudioEngine = AVAudioEngine()
    private var wakeWords = ["hey one rep", "one rep", "hey onerep", "onerep", "hey gym", "gym"]

    // Audio recording for Whisper fallback
    private var audioRecorder: AVAudioRecorder?
    private var recordedAudioURL: URL?

    // Confidence threshold - below this, use Whisper fallback
    private let confidenceThreshold: Float = 0.7

    // Command callback
    var onCommand: ((VoiceCommand) -> Void)?

    // Known exercise names for matching (with variations)
    private var knownExercises: [String] = []
    private var exerciseAliases: [String: String] = [:]

    // MARK: - Initialization
    private override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        os_log("VoiceCommandService: Initializing", log: log, type: .info)

        // Load saved preferences
        isVoiceControlEnabled = UserDefaults.standard.bool(forKey: "voiceControlEnabled")
        useWhisperFallback = UserDefaults.standard.object(forKey: "useWhisperFallback") as? Bool ?? true
        isContinuousListeningEnabled = UserDefaults.standard.bool(forKey: "continuousListeningEnabled")
        
        os_log("VoiceCommandService: Prefs - voiceControl=%{public}@, whisperFallback=%{public}@, continuousListening=%{public}@",
               log: log, type: .info,
               isVoiceControlEnabled ? "ON" : "OFF",
               useWhisperFallback ? "ON" : "OFF",
               isContinuousListeningEnabled ? "ON" : "OFF")

        // Check authorization status
        checkAuthorizationStatus()
        
        // Setup audio session interruption handling
        setupInterruptionHandling()

        // Setup remote command center if enabled
        if isVoiceControlEnabled {
            setupRemoteCommandCenter()
        }

        // Setup common exercise aliases for fuzzy matching
        setupExerciseAliases()
        
        os_log("VoiceCommandService: Initialization complete", log: log, type: .info)
    }
    
    // MARK: - Audio Session State
    private var isAudioInterrupted = false
    
    // MARK: - Interruption Handling
    private func setupInterruptionHandling() {
        // Register for audio session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Register for route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        os_log("VoiceCommandService: Interruption handling configured", log: log, type: .info)
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            os_log("VoiceCommandService: ⚠️ AUDIO INTERRUPTED - stopping recognition", log: log, type: .info)
            isAudioInterrupted = true
            stopListening()
            stopContinuousListening()
            
        case .ended:
            os_log("VoiceCommandService: ✅ Interruption ended", log: log, type: .info)
            isAudioInterrupted = false
            
            var shouldResume = false
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            }
            
            os_log("VoiceCommandService: Should resume: %{public}@", log: log, type: .info, shouldResume ? "YES" : "NO")
            
            // Restart continuous listening if it was enabled
            if shouldResume && isContinuousListeningEnabled && isVoiceControlEnabled {
                os_log("VoiceCommandService: Restarting continuous listening after interruption", log: log, type: .info)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.startContinuousListening()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        os_log("VoiceCommandService: 🔊 Audio route changed (reason=%{public}d)", log: log, type: .info, Int(reason.rawValue))
        
        // If continuous listening was active and device changed, restart it
        if isContinuouslyListening && (reason == .oldDeviceUnavailable || reason == .newDeviceAvailable) {
            os_log("VoiceCommandService: Restarting continuous listening after route change", log: log, type: .info)
            restartContinuousListening()
        }
    }

    // MARK: - Continuous Listening (Wake Word Detection)
    func startContinuousListening() {
        os_log("VoiceCommandService: startContinuousListening called", log: log, type: .info)
        
        guard isAuthorized else {
            os_log("VoiceCommandService: Not authorized, requesting...", log: log, type: .info)
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.startContinuousListening()
                }
            }
            return
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            os_log("VoiceCommandService: Speech recognizer not available", log: log, type: .error)
            return
        }

        // Don't start if already listening
        guard !isContinuouslyListening else {
            os_log("VoiceCommandService: Already listening, skipping", log: log, type: .info)
            return
        }
        
        // Clear interrupted flag - music from another app sets this but never clears it
        if isAudioInterrupted {
            os_log("VoiceCommandService: Clearing interrupted flag for continuous listening", log: log, type: .info)
            isAudioInterrupted = false
        }

        do {
            // Configure audio session for voice recognition
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            os_log("VoiceCommandService: Audio session configured for voice recognition", log: log, type: .info)

            continuousRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let request = continuousRecognitionRequest else { return }

            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true  // Use on-device for lower latency

            let inputNode = continuousAudioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.continuousRecognitionRequest?.append(buffer)
            }

            continuousAudioEngine.prepare()
            try continuousAudioEngine.start()

            isContinuouslyListening = true
            os_log("VoiceCommandService: ✅ Continuous listening STARTED", log: log, type: .info)

            continuousRecognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    let text = result.bestTranscription.formattedString.lowercased()

                    // Check for wake word
                    for wakeWord in self.wakeWords {
                        if text.contains(wakeWord) {
                            os_log("VoiceCommandService: 🎤 WAKE WORD DETECTED: '%{public}@' in '%{public}@'", log: self.log, type: .info, wakeWord, text)
                            
                            // Found wake word - extract command after it
                            if let range = text.range(of: wakeWord) {
                                let commandPart = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                                if !commandPart.isEmpty {
                                    os_log("VoiceCommandService: 🗣️ Command after wake word: '%{public}@'", log: self.log, type: .info, commandPart)
                                    
                                    // We have a command after the wake word
                                    DispatchQueue.main.async {
                                        self.wakeWordDetected = true
                                        self.processCommand(commandPart)

                                        // Reset wake word detection after brief delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            self.wakeWordDetected = false
                                        }
                                    }

                                    // Restart continuous listening
                                    self.restartContinuousListening()
                                    return
                                }
                            }
                        }
                    }
                }

                if let error = error {
                    os_log("VoiceCommandService: ⚠️ Recognition error: %{public}@", log: self.log, type: .error, error.localizedDescription)
                    // Restart on error
                    self.restartContinuousListening()
                }
            }

        } catch {
            os_log("VoiceCommandService: ❌ Continuous listening FAILED: %{public}@", log: log, type: .error, error.localizedDescription)
            isContinuouslyListening = false
        }
    }

    func stopContinuousListening() {
        os_log("VoiceCommandService: Stopping continuous listening", log: log, type: .info)
        
        continuousAudioEngine.stop()
        if continuousAudioEngine.inputNode.numberOfInputs > 0 {
            continuousAudioEngine.inputNode.removeTap(onBus: 0)
        }
        continuousRecognitionRequest?.endAudio()
        continuousRecognitionRequest = nil
        continuousRecognitionTask?.cancel()
        continuousRecognitionTask = nil

        DispatchQueue.main.async {
            self.isContinuouslyListening = false
        }
        
        os_log("VoiceCommandService: Continuous listening STOPPED", log: log, type: .info)
    }

    private func restartContinuousListening() {
        stopContinuousListening()

        // Brief delay before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self,
                  self.isContinuousListeningEnabled,
                  self.isVoiceControlEnabled else { return }
            self.startContinuousListening()
        }
    }

    private func setupExerciseAliases() {
        exerciseAliases = [
            // Leg exercises
            "leg press": "Leg Press",
            "press legs": "Leg Press",
            "leg curl": "Leg Curl",
            "curl legs": "Leg Curl",
            "hamstring curl": "Leg Curl",
            "leg extension": "Leg Extension",
            "extend legs": "Leg Extension",
            "quad extension": "Leg Extension",
            "calf raise": "Calf Raise",
            "calf raises": "Calf Raise",
            "calves": "Calf Raise",

            // Chest exercises
            "chest press": "Chest Press",
            "press chest": "Chest Press",
            "bench press": "Chest Press",
            "incline press": "Incline Press",
            "incline": "Incline Press",

            // Back exercises
            "pulldown": "Pulldown",
            "pull down": "Pulldown",
            "lat pulldown": "Pulldown",
            "lats": "Pulldown",
            "seated row": "Seated Row",
            "row": "Seated Row",
            "rowing": "Seated Row",
            "back row": "Seated Row",

            // Shoulder exercises
            "overhead press": "Overhead Press",
            "shoulder press": "Overhead Press",
            "press overhead": "Overhead Press",
            "military press": "Overhead Press",
            "lateral raise": "Lateral Raise",
            "side raise": "Lateral Raise",
            "lateral raises": "Lateral Raise",
            "shrug": "Shrug",
            "shrugs": "Shrug",
            "shoulder shrug": "Shrug",

            // Arm exercises
            "bicep curl": "Bicep Curl",
            "biceps": "Bicep Curl",
            "curl biceps": "Bicep Curl",
            "arm curl": "Bicep Curl",
            "tricep extension": "Tricep Extension",
            "triceps": "Tricep Extension",
            "tricep": "Tricep Extension",

            // Core exercises
            "ab crunch": "Ab Crunch",
            "abs": "Ab Crunch",
            "crunches": "Ab Crunch",
            "abdominal": "Ab Crunch",
            "back extension": "Back Extension",
            "lower back": "Back Extension",
            "hyperextension": "Back Extension",
        ]
    }

    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition not authorized"
                    completion(false)
                @unknown default:
                    self?.isAuthorized = false
                    completion(false)
                }
            }
        }
    }

    private func checkAuthorizationStatus() {
        let status = SFSpeechRecognizer.authorizationStatus()
        DispatchQueue.main.async {
            self.isAuthorized = (status == .authorized)
        }
    }

    // MARK: - Update Known Exercises
    func updateKnownExercises(_ exercises: [String]) {
        knownExercises = exercises.map { $0.lowercased() }
        // Also add to aliases
        for exercise in exercises {
            exerciseAliases[exercise.lowercased()] = exercise
        }
    }

    // MARK: - Start Listening (Hybrid: iOS Speech + Whisper Fallback)
    func startListening() {
        os_log("VoiceCommandService: startListening called", log: log, type: .info)
        
        guard isAuthorized else {
            os_log("VoiceCommandService: Not authorized for single-shot listening", log: log, type: .info)
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.startListening()
                }
            }
            return
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            os_log("VoiceCommandService: Speech recognizer not available, trying Whisper", log: log, type: .info)
            // If iOS speech not available, try Whisper directly
            if useWhisperFallback && WhisperAPIService.shared.isConfigured {
                startWhisperRecording()
            } else {
                errorMessage = "Speech recognition not available"
                os_log("VoiceCommandService: ❌ No speech recognition available", log: log, type: .error)
            }
            return
        }
        
        // Clear interrupted flag when user explicitly requests listening
        // Music playing from another app sets this flag but never clears it
        if isAudioInterrupted {
            os_log("VoiceCommandService: Clearing interrupted flag - user initiated listening", log: log, type: .info)
            isAudioInterrupted = false
        }

        // Stop any existing recognition
        stopListening()

        do {
            // Configure audio session for voice recognition
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            os_log("VoiceCommandService: Audio session configured for voice recognition", log: log, type: .info)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create recognition request"
                return
            }

            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = false

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Also start recording audio file for potential Whisper fallback
            if useWhisperFallback && WhisperAPIService.shared.isConfigured {
                startAudioFileRecording()
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isListening = true
            transcribedText = ""

            var lastConfidence: Float = 0.0

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    let transcription = result.bestTranscription.formattedString

                    // Calculate confidence from segments
                    let segments = result.bestTranscription.segments
                    if !segments.isEmpty {
                        lastConfidence = segments.map { Float($0.confidence) }.reduce(0, +) / Float(segments.count)
                    }

                    DispatchQueue.main.async {
                        self.transcribedText = transcription
                    }

                    if result.isFinal {
                        self.handleRecognitionResult(
                            RecognitionResult(text: transcription, confidence: lastConfidence, isFinal: true)
                        )
                    }
                }

                if error != nil {
                    // On error, try Whisper if we have recorded audio
                    self.tryWhisperFallback()
                }
            }

            // Auto-stop after 5 seconds of listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if self?.isListening == true {
                    let currentText = self?.transcribedText ?? ""
                    self?.stopListening()
                    if !currentText.isEmpty {
                        // Process with whatever confidence we have
                        self?.handleRecognitionResult(
                            RecognitionResult(text: currentText, confidence: lastConfidence, isFinal: true)
                        )
                    }
                }
            }

        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            isListening = false
        }
    }

    // MARK: - Handle Recognition Result (with Whisper fallback)
    private func handleRecognitionResult(_ result: RecognitionResult) {
        stopAudioFileRecording()

        // If confidence is low and Whisper is configured, use Whisper
        if result.confidence < confidenceThreshold &&
           useWhisperFallback &&
           WhisperAPIService.shared.isConfigured,
           let audioURL = recordedAudioURL {

            isProcessingWithWhisper = true
            WhisperAPIService.shared.transcribe(fileURL: audioURL) { [weak self] whisperResult in
                self?.isProcessingWithWhisper = false

                switch whisperResult {
                case .success(let whisperText):
                    // Use Whisper's transcription
                    self?.processCommand(whisperText)
                case .failure:
                    // Fall back to iOS transcription
                    self?.processCommand(result.text)
                }

                // Cleanup audio file
                self?.cleanupRecordedAudio()
            }
        } else {
            // Confidence is good, use iOS transcription
            processCommand(result.text)
            cleanupRecordedAudio()
        }

        stopListening()
    }

    // MARK: - Whisper-Only Recording
    private func startWhisperRecording() {
        startAudioFileRecording()
        isListening = true

        // Record for 5 seconds then process with Whisper
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.stopAudioFileRecording()
            self?.isListening = false
            self?.tryWhisperFallback()
        }
    }

    private func tryWhisperFallback() {
        guard useWhisperFallback,
              WhisperAPIService.shared.isConfigured,
              let audioURL = recordedAudioURL else {
            stopListening()
            return
        }

        isProcessingWithWhisper = true
        WhisperAPIService.shared.transcribe(fileURL: audioURL) { [weak self] result in
            self?.isProcessingWithWhisper = false
            self?.stopListening()

            switch result {
            case .success(let text):
                self?.processCommand(text)
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }

            self?.cleanupRecordedAudio()
        }
    }

    // MARK: - Audio File Recording (for Whisper)
    private func startAudioFileRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordedAudioURL = documentsPath.appendingPathComponent("voice_command_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordedAudioURL!, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Failed to start audio recording: \(error)")
        }
    }

    private func stopAudioFileRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }

    private func cleanupRecordedAudio() {
        if let url = recordedAudioURL {
            try? FileManager.default.removeItem(at: url)
            recordedAudioURL = nil
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        stopAudioFileRecording()

        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    // MARK: - Process Voice Command
    private func processCommand(_ text: String) {
        os_log("VoiceCommandService: Processing command - raw: '%{public}@'", log: log, type: .info, text)
        
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove common filler words and punctuation
        let cleaned = cleanTranscription(lowercased)
        os_log("VoiceCommandService: Cleaned text: '%{public}@'", log: log, type: .info, cleaned)

        let command = parseCommand(cleaned)
        os_log("VoiceCommandService: 🎯 Parsed command: %{public}@", log: log, type: .info, String(describing: command))

        DispatchQueue.main.async {
            self.transcribedText = text
            self.lastCommand = command
            self.onCommand?(command)
        }
    }

    private func cleanTranscription(_ text: String) -> String {
        var cleaned = text
        // Remove punctuation
        cleaned = cleaned.replacingOccurrences(of: ".", with: "")
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        cleaned = cleaned.replacingOccurrences(of: "?", with: "")
        cleaned = cleaned.replacingOccurrences(of: "!", with: "")

        // Remove common filler words
        let fillers = ["please", "can you", "could you", "i want to", "i'd like to", "um", "uh", "the", "a", "an"]
        for filler in fillers {
            cleaned = cleaned.replacingOccurrences(of: filler, with: " ")
        }

        // Collapse multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private func parseCommand(_ text: String) -> VoiceCommand {
        // Check for weight logging commands first (e.g., "log 150", "150 pounds")
        if let weight = extractWeight(from: text) {
            return .logWeight(weight)
        }

        // Check for exercise start commands
        let startTriggers = ["start", "begin", "do", "let's do", "lets do", "go to"]
        for trigger in startTriggers {
            if text.contains(trigger) {
                let afterTrigger = text.replacingOccurrences(of: trigger, with: "").trimmingCharacters(in: .whitespaces)

                // Check against known exercises and aliases
                if let matchedExercise = findMatchingExercise(afterTrigger) {
                    return .startExercise(matchedExercise)
                }

                // If we have text after trigger, try fuzzy match
                if !afterTrigger.isEmpty {
                    if let fuzzyMatch = fuzzyMatchExercise(afterTrigger) {
                        return .startExercise(fuzzyMatch)
                    }
                    // Last resort: capitalize and use as-is
                    return .startExercise(afterTrigger.split(separator: " ").map { $0.capitalized }.joined(separator: " "))
                }
            }
        }

        // Check if text itself is an exercise name (without "start")
        if let matchedExercise = findMatchingExercise(text) {
            return .startExercise(matchedExercise)
        }

        // Navigation commands with variations
        let nextTriggers = ["next exercise", "next one", "move on", "next"]
        for trigger in nextTriggers {
            if text.contains(trigger) || text == trigger.trimmingCharacters(in: .whitespaces) {
                return .nextExercise
            }
        }

        // Skip rest variations
        let skipRestTriggers = ["skip rest", "skip the rest", "end rest", "no rest", "ready"]
        for trigger in skipRestTriggers {
            if text.contains(trigger) {
                return .skipRest
            }
        }

        // Skip phase variations
        let skipTriggers = ["skip", "skip phase", "skip this", "next phase"]
        for trigger in skipTriggers {
            if text == trigger || text.contains(trigger) {
                return .skipPhase
            }
        }

        // Pause variations
        let pauseTriggers = ["pause", "hold", "wait", "stop timer"]
        for trigger in pauseTriggers {
            if text == trigger || text.contains(trigger) {
                return .pause
            }
        }

        // Resume variations
        let resumeTriggers = ["resume", "continue", "go", "unpause", "start timer"]
        for trigger in resumeTriggers {
            if text == trigger || text.contains(trigger) {
                return .resume
            }
        }

        // Stop workout variations
        let stopTriggers = ["stop workout", "end workout", "stop", "quit", "finish workout", "i'm done with workout"]
        for trigger in stopTriggers {
            if text.contains(trigger) {
                return .stop
            }
        }

        // Done/complete exercise variations
        let doneTriggers = ["done", "finished", "complete", "i'm done", "im done", "that's it", "thats it"]
        for trigger in doneTriggers {
            if text == trigger || text.contains(trigger) {
                return .done
            }
        }

        // Another set variations
        let anotherSetTriggers = ["another set", "one more", "again", "repeat", "same exercise", "do it again"]
        for trigger in anotherSetTriggers {
            if text.contains(trigger) {
                return .anotherSet
            }
        }

        return .unknown(text)
    }

    private func extractWeight(from text: String) -> Int? {
        // Match patterns like "log 150", "150 pounds", "150 lbs", "weight 150"
        let patterns = [
            "log (\\d+)",
            "(\\d+) pounds",
            "(\\d+) lbs",
            "(\\d+) lb",
            "weight (\\d+)",
            "set weight (\\d+)",
            "(\\d+)"  // Just a number if context suggests weight
        ]

        // Only match standalone number if text also contains weight-related words
        let weightKeywords = ["log", "weight", "pound", "lbs", "lb", "set"]
        let hasWeightKeyword = weightKeywords.contains { text.contains($0) }

        for (index, pattern) in patterns.enumerated() {
            // Skip standalone number pattern unless we have weight keywords
            if index == patterns.count - 1 && !hasWeightKeyword {
                continue
            }

            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                if let weight = Int(text[range]) {
                    return weight
                }
            }
        }

        return nil
    }

    private func findMatchingExercise(_ text: String) -> String? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespaces)

        // Check aliases first (includes common variations)
        if let aliasMatch = exerciseAliases[lowercased] {
            return aliasMatch
        }

        // Check known exercises
        for exercise in knownExercises {
            if lowercased == exercise {
                return exercise.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
            }
        }

        // Partial match in aliases
        for (alias, name) in exerciseAliases {
            if lowercased.contains(alias) || alias.contains(lowercased) {
                return name
            }
        }

        // Partial match in known exercises
        for exercise in knownExercises {
            if lowercased.contains(exercise) || exercise.contains(lowercased) {
                return exercise.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
            }
        }

        return nil
    }

    private func fuzzyMatchExercise(_ text: String) -> String? {
        let lowercased = text.lowercased()
        var bestMatch: (name: String, score: Int)?

        // Check all aliases
        for (alias, name) in exerciseAliases {
            let score = fuzzyScore(query: lowercased, target: alias)
            if score > 50 {  // Minimum threshold
                if bestMatch == nil || score > bestMatch!.score {
                    bestMatch = (name, score)
                }
            }
        }

        // Check known exercises
        for exercise in knownExercises {
            let score = fuzzyScore(query: lowercased, target: exercise)
            if score > 50 {
                if bestMatch == nil || score > bestMatch!.score {
                    bestMatch = (exercise.split(separator: " ").map { $0.capitalized }.joined(separator: " "), score)
                }
            }
        }

        return bestMatch?.name
    }

    // Simple fuzzy matching score (0-100)
    private func fuzzyScore(query: String, target: String) -> Int {
        if query == target { return 100 }
        if target.contains(query) { return 80 }
        if query.contains(target) { return 70 }

        // Check word overlap
        let queryWords = Set(query.split(separator: " ").map { String($0) })
        let targetWords = Set(target.split(separator: " ").map { String($0) })
        let overlap = queryWords.intersection(targetWords).count

        if overlap > 0 {
            return 50 + (overlap * 15)
        }

        // Check Levenshtein-like similarity for short strings
        let distance = levenshteinDistance(query, target)
        let maxLen = max(query.count, target.count)
        if maxLen > 0 {
            let similarity = 100 - (distance * 100 / maxLen)
            return max(0, similarity)
        }

        return 0
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count { matrix[i][0] = i }
        for j in 0...s2Array.count { matrix[0][j] = j }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    // MARK: - Remote Command Center (Earbud Button)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play/Pause button on earbuds triggers voice listening
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.toggleListening()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.toggleListening()
            return .success
        }

        // Setup Now Playing info to enable remote commands
        setupNowPlayingInfo()
    }

    private func removeRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
    }

    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "OneRepStrength"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Workout Active"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            // Play audio cue
            playListeningSound()
            startListening()
        }
    }

    private func playListeningSound() {
        AudioServicesPlaySystemSound(1113) // Begin Recording sound
    }

    // MARK: - Spoken Feedback
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

// MARK: - Voice Command Handler Extension for WorkoutManager
extension WorkoutManager {
    func handleVoiceCommand(_ command: VoiceCommand) {
        switch command {
        case .startExercise(let name):
            // Try exact match first, then fuzzy match
            let lowercasedName = name.lowercased()
            if let exercise = currentWorkout.exercises.first(where: {
                $0.name.lowercased() == lowercasedName
            }) ?? currentWorkout.exercises.first(where: {
                $0.name.lowercased().contains(lowercasedName) ||
                lowercasedName.contains($0.name.lowercased())
            }) {
                startExercise(exercise)
                VoiceCommandService.shared.speak("Starting \(exercise.name)")
            } else {
                VoiceCommandService.shared.speak("Exercise not found: \(name)")
            }

        case .nextExercise:
            if let next = nextExercise {
                startExercise(next)
                VoiceCommandService.shared.speak("Next: \(next.name)")
            } else {
                VoiceCommandService.shared.speak("No more exercises")
            }

        case .skipPhase:
            skipPhase()
            VoiceCommandService.shared.speak("Skipped")

        case .pause:
            pauseTimer()
            VoiceCommandService.shared.speak("Paused")

        case .resume:
            resumeTimer()
            VoiceCommandService.shared.speak("Resuming")

        case .stop:
            stopTimer()
            VoiceCommandService.shared.speak("Workout stopped")

        case .done:
            completeExercise()
            VoiceCommandService.shared.speak("Exercise complete")

        case .skipRest:
            skipRest()
            VoiceCommandService.shared.speak("Skipping rest")

        case .anotherSet:
            anotherSet()
            VoiceCommandService.shared.speak("Starting another set")

        case .logWeight(let weight):
            // Log weight for current exercise
            if let exercise = currentExercise,
               let index = currentWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                currentWorkout.exercises[index].lastWeight = Double(weight)
                let key = "exerciseWeight_\(currentProfile)_\(exercise.name)"
                UserDefaults.standard.set(Double(weight), forKey: key)
                VoiceCommandService.shared.speak("Logged \(weight) pounds")
            } else {
                VoiceCommandService.shared.speak("No exercise selected")
            }

        case .unknown(let text):
            // Don't speak for short gibberish
            if text.count > 2 {
                VoiceCommandService.shared.speak("Try again")
            }
        }
    }
}
