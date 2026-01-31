// ProfileManager.swift
import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [Profile] = []
    @Published var currentProfile: Profile = Profile(id: 1, name: "User 1")
    
    private let profilesKey = "savedProfiles"
    private let currentProfileIdKey = "currentProfileId"
    
    init() {
        // Load profiles
        var loadedProfiles: [Profile] = []
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let savedProfiles = try? JSONDecoder().decode([Profile].self, from: data),
           !savedProfiles.isEmpty {
            loadedProfiles = savedProfiles
        } else {
            // Default profiles
            loadedProfiles = [
                Profile(id: 1, name: "User 1"),
                Profile(id: 2, name: "User 2")
            ]
        }
        self.profiles = loadedProfiles
        
        // Load current profile
        let savedId = UserDefaults.standard.integer(forKey: currentProfileIdKey)
        if let profile = loadedProfiles.first(where: { $0.id == savedId }) {
            self.currentProfile = profile
        } else {
            self.currentProfile = loadedProfiles.first ?? Profile(id: 1, name: "User 1")
        }
    }
    
    func createProfile(name: String) {
        let newId = (profiles.map { $0.id }.max() ?? 0) + 1
        let newProfile = Profile(id: newId, name: name)
        profiles.append(newProfile)
        saveProfiles()
    }
    
    func switchProfile(to profile: Profile) {
        currentProfile = profile
        UserDefaults.standard.set(profile.id, forKey: currentProfileIdKey)
        // Views observing ProfileManager will react to currentProfile change
    }
    
    func deleteProfile(_ profile: Profile) {
        guard profiles.count > 1 else { return } // Prevent deleting last profile
        profiles.removeAll { $0.id == profile.id }
        
        if currentProfile.id == profile.id {
            currentProfile = profiles.first!
            UserDefaults.standard.set(currentProfile.id, forKey: currentProfileIdKey)
        }
        saveProfiles()
    }
    
    func updateCurrentProfile(name: String, voiceStyle: AudioManager.VoiceStyle) {
        if let index = profiles.firstIndex(where: { $0.id == currentProfile.id }) {
            var updated = profiles[index]
            updated.name = name
            updated.voiceStyle = voiceStyle
            profiles[index] = updated
            currentProfile = updated
            saveProfiles()
        }
    }
    
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }
}
