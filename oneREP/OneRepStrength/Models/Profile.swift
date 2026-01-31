// Profile.swift
import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: Int
    var name: String
    var createdAt: Date
    var voiceStyle: AudioManager.VoiceStyle
    
    // Default settings per profile could go here
    
    init(id: Int = 1, name: String, createdAt: Date = Date(), voiceStyle: AudioManager.VoiceStyle = .commander) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.voiceStyle = voiceStyle
    }
    
    static let `default` = Profile(name: "Default User")
}
