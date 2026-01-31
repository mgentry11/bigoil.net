//
//  WhisperAPIService.swift
//  OneRepStrength
//
//  OpenAI Whisper API integration for improved speech-to-text accuracy.
//  Used as a fallback when iOS speech recognition has low confidence.
//

import Foundation
import AVFoundation

// MARK: - Whisper API Response
struct WhisperResponse: Codable {
    let text: String
}

// MARK: - Whisper API Service
class WhisperAPIService {
    static let shared = WhisperAPIService()

    // Store API key securely - user should set this in Settings
    private var apiKey: String? {
        get { KeychainHelper.load(key: "whisperAPIKey") }
        set {
            if let key = newValue {
                KeychainHelper.save(key: "whisperAPIKey", value: key)
            } else {
                KeychainHelper.delete(key: "whisperAPIKey")
            }
        }
    }

    var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"

    private init() {}

    // MARK: - Set API Key
    func setAPIKey(_ key: String) {
        apiKey = key
    }

    func clearAPIKey() {
        apiKey = nil
    }

    // MARK: - Transcribe Audio
    func transcribe(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(WhisperError.noAPIKey))
            return
        }

        guard let url = URL(string: baseURL) else {
            completion(.failure(WhisperError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Add language parameter (English)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)

        // Add prompt for better accuracy with workout terms
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("Workout commands: start, next, skip, pause, resume, stop, done, leg press, chest press, pulldown, seated row, overhead press, leg curl, leg extension, bicep curl, tricep extension, calf raise, lateral raise, shrug, ab crunch, back extension, incline press\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(WhisperError.noData))
                }
                return
            }

            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    completion(.failure(WhisperError.apiError(errorMessage)))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(WhisperResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.text))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Transcribe Audio File
    func transcribe(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let audioData = try Data(contentsOf: fileURL)
            transcribe(audioData: audioData, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Whisper Errors
enum WhisperError: LocalizedError {
    case noAPIKey
    case invalidURL
    case noData
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Whisper API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

// MARK: - Simple Keychain Helper
class KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
