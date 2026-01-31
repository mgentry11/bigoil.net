// ElevenLabsService.swift
import Foundation
import AVFoundation

enum ElevenLabsError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case noData
}

class ElevenLabsService: ObservableObject {
    static let shared = ElevenLabsService()
    
    // Default API Key from user
    private let defaultAPIKey = "sk_75d2b652bbbf2f875b28fb52dabf5c3feb5b1c1414435b8b"
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    // Default Voice ID (Antoni as generic fallback)
    @Published var selectedVoiceID: String = "ErXwobaYiN019PkySvjV"
    
    private var apiKey: String {
        // ... (existing implementation)
        if let storedKey = SecureStorage.shared.loadData(forKey: "elevenLabsAPIKey"),
           let keyString = String(data: storedKey, encoding: .utf8), !keyString.isEmpty {
            return keyString
        }
        return defaultAPIKey
    }
    
    private var audioCache: [String: Data] = [:]
    
    private init() {
        fetchVoices()
    }
    
    struct VoiceResponse: Decodable {
        let voices: [Voice]
    }
    
    struct Voice: Decodable {
        let voice_id: String
        let name: String
    }
    
    func fetchVoices() {
        guard let url = URL(string: "\(baseURL)/voices") else { return }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                let response = try JSONDecoder().decode(VoiceResponse.self, from: data)
                // Look for "Commander" voice (case insensitive)
                if let commander = response.voices.first(where: { $0.name.localizedCaseInsensitiveContains("Commander") }) {
                    DispatchQueue.main.async {
                        print("Found Commander voice: \(commander.name) (\(commander.voice_id))")
                        self?.selectedVoiceID = commander.voice_id
                    }
                } else {
                    print("Commander voice not found, using default.")
                }
            } catch {
                print("Failed to decode voices: \(error)")
            }
        }.resume()
    }
    
    /// Generate audio for text and return the local file URL
    func generateAudio(text: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // specific cache check
        let cacheKey = "\(selectedVoiceID)_\(text)"
        if let cachedData = audioCache[cacheKey] {
            saveToTempFile(data: cachedData, completion: completion)
            return
        }
        
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(selectedVoiceID)") else {
            completion(.failure(ElevenLabsError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(ElevenLabsError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ElevenLabsError.invalidResponse))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let message = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                print("ElevenLabs API Error: \(httpResponse.statusCode) - \(message)")
                completion(.failure(ElevenLabsError.apiError("Status: \(httpResponse.statusCode)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(ElevenLabsError.noData))
                return
            }
            
            // Cache results
            self?.audioCache[cacheKey] = data
            self?.saveToTempFile(data: data, completion: completion)
            
        }.resume()
    }
    
    private func saveToTempFile(data: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".mp3"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Pre-fetch commonly used phrases to cache them
    func prefetchCommonPhrases() {
        let phrases = [
            "Rest starting",
            "3, 2, 1, Go",
            "Workout complete"
        ]
        
        for phrase in phrases {
            generateAudio(text: phrase) { _ in }
        }
    }
}
