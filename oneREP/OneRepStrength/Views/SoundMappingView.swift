import SwiftUI
import AVFoundation

struct SoundMappingView: View {
    @StateObject private var mappingManager = SoundMappingManager.shared
    @StateObject private var audioPlayer = AudioPlayer()
    
    // Scan for voice_XXX.mp3 files
    var availableFiles: [String] {
        return mappingManager.getAvailableAudioFiles()
    }
    
    var body: some View {
        List {
            Section {
                Text("Tap an event to assign an audio file. Tap the Play button to preview a file.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .listRowBackground(Color.clear)
            
            ForEach(SoundMappingManager.supportedKeys, id: \.1) { (label, key) in
                NavigationLink(destination: FilePickerView(
                    eventLabel: label,
                    eventKey: key,
                    availableFiles: availableFiles,
                    currentFile: mappingManager.mappings[key],
                    onSelect: { file in
                        mappingManager.setMapping(key: key, filename: file)
                    },
                    audioPlayer: audioPlayer
                )) {
                    HStack {
                        Text(label)
                            .foregroundColor(ThemeManager.shared.text)
                        Spacer()
                        if let file = mappingManager.mappings[key] {
                            Text(file)
                                .font(.caption)
                                .foregroundColor(ThemeManager.shared.primary)
                        } else {
                            Text("Unassigned")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowBackground(Color.clear.background(.thickMaterial))
            }
        }
        .background(ThemeManager.shared.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("Map Sounds")
    }
}

struct FilePickerView: View {
    let eventLabel: String
    let eventKey: String
    let availableFiles: [String]
    let currentFile: String?
    let onSelect: (String) -> Void
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        List {
            ForEach(availableFiles, id: \.self) { file in
                HStack {
                    Button(action: {
                        onSelect(file)
                    }) {
                        HStack {
                            Text(file)
                                .foregroundColor(ThemeManager.shared.text)
                            Spacer()
                            if file == currentFile {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ThemeManager.shared.primary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        audioPlayer.play(file: file)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(ThemeManager.shared.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listRowBackground(Color.clear.background(.thickMaterial))
            }
        }
        .background(ThemeManager.shared.background)
        .scrollContentBackground(.hidden)
        .navigationTitle(eventLabel)
    }
}

class AudioPlayer: ObservableObject {
    var player: AVAudioPlayer?
    
    init() {
        // Ensure playback happens even if silent switch is on
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func play(file: String) {
        // Try flat lookup first
        var url = Bundle.main.url(forResource: file, withExtension: "mp3")
        
        // Try 'Audio' subdirectory if flat failed
        if url == nil {
            url = Bundle.main.url(forResource: file, withExtension: "mp3", subdirectory: "Audio")
        }
        
        guard let finalUrl = url else {
            print("File not found: \(file) (checked flat and Audio/ subdirectory)")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: finalUrl)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Playback failed: \(error)")
        }
    }
}
