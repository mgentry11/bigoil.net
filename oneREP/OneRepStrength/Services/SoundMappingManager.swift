import Foundation
import Combine

class SoundMappingManager: ObservableObject {
    static let shared = SoundMappingManager()
    
    private let defaultsKey = "commander_sound_mappings"
    
    // Mapping from Event Key (e.g. "workout_begin") to File Name (e.g. "voice_001")
    @Published var mappings: [String: String] = [:] {
        didSet {
            saveMappings()
        }
    }
    
    init() {
        // Force reset to load corrected mappings (one-time fix)
        let resetKey = "commander_mappings_v7_aliases"
        if !UserDefaults.standard.bool(forKey: resetKey) {
            print("[SoundMappingManager] Resetting to v7 with exercise aliases")
            UserDefaults.standard.removeObject(forKey: defaultsKey)
            UserDefaults.standard.set(true, forKey: resetKey)
        }
        loadMappings()
    }
    
    private func loadMappings() {
        print("[SoundMappingManager] loadMappings called")
        
        // Try to load user's custom mappings first
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data),
           !decoded.isEmpty {
            mappings = decoded
            print("[SoundMappingManager] Loaded \(decoded.count) mappings from UserDefaults")
            return
        }
        
        print("[SoundMappingManager] No UserDefaults mappings, loading defaults...")
        // If no custom mappings, load defaults from bundled JSON
        loadDefaultMappings()
    }
    
    private func loadDefaultMappings() {
        print("[SoundMappingManager] loadDefaultMappings called - using hardcoded mappings")
        
        // Complete hardcoded mappings (voice_XXX format)
        let defaults: [String: String] = [
            // Countdown numbers (count_1 = voice_015, count_10 = voice_024 based on file order)
            // Numbers 11-60 continue from voice_025 to voice_074
            "count_1": "voice_015",
            "count_2": "voice_016",
            "count_3": "voice_017",
            "count_4": "voice_018",
            "count_5": "voice_019",
            "count_6": "voice_020",
            "count_7": "voice_021",
            "count_8": "voice_022",
            "count_9": "voice_023",
            "count_10": "voice_024",
            "count_11": "voice_025",
            "count_12": "voice_026",
            "count_13": "voice_027",
            "count_14": "voice_028",
            "count_15": "voice_029",
            "count_16": "voice_030",
            "count_17": "voice_031",
            "count_18": "voice_032",
            "count_19": "voice_033",
            "count_20": "voice_034",
            "count_21": "voice_035",
            "count_22": "voice_036",
            "count_23": "voice_037",
            "count_24": "voice_038",
            "count_25": "voice_039",
            "count_26": "voice_040",
            "count_27": "voice_041",
            "count_28": "voice_042",
            "count_29": "voice_043",
            "count_30": "voice_044",
            "count_31": "voice_045",
            "count_32": "voice_046",
            "count_33": "voice_047",
            "count_34": "voice_048",
            "count_35": "voice_049",
            "count_36": "voice_050",
            "count_37": "voice_051",
            "count_38": "voice_052",
            "count_39": "voice_053",
            "count_40": "voice_054",
            "count_41": "voice_055",
            "count_42": "voice_056",
            "count_43": "voice_057",
            "count_44": "voice_058",
            "count_45": "voice_059",
            "count_46": "voice_060",
            "count_47": "voice_061",
            "count_48": "voice_062",
            "count_49": "voice_063",
            "count_50": "voice_064",
            "count_51": "voice_065",
            "count_52": "voice_066",
            "count_53": "voice_067",
            "count_54": "voice_068",
            "count_55": "voice_069",
            "count_56": "voice_070",
            "count_57": "voice_071",
            "count_58": "voice_072",
            "count_59": "voice_073",
            "count_60": "voice_074",
            
            // Phase cues
            "phase_get_ready": "voice_001",
            "phase_position": "voice_002",
            "phase_eccentric": "voice_003",
            "phase_concentric": "voice_004",
            "phase_final_eccentric": "voice_005",
            "phase_complete": "voice_006",
            
            // Time cues
            "time_halfway": "voice_079",
            "time_almost": "voice_112",
            "time_almost_done": "voice_080",
            "time_10_sec": "voice_077",
            "time_5_sec": "voice_078",
            "time_30_sec": "voice_075",
            "time_20_sec": "voice_076",
            
            // Rest cues
            "rest_starting": "voice_007",
            "rest_breathe": "voice_123",
            "rest_recover": "voice_124",
            "rest_get_ready": "voice_125",
            "rest_30_sec": "voice_126",
            "rest_15_sec": "voice_127",
            "rest_next_coming": "voice_128",
            "rest_complete": "voice_129",
            
            // Transition cues
            "trans_next": "voice_130",
            "trans_moving": "voice_131",
            "trans_prepare": "voice_132",
            
            // Workout cues
            "workout_starting": "voice_133",
            "workout_begin": "voice_134",
            "workout_complete": "voice_135",
            "workout_great_session": "voice_136",
            "workout_crushed": "voice_137",
            "workout_see_you": "voice_138",
            
            // Eccentric cues
            "ecc_lower_slowly": "voice_086",
            "ecc_control_weight": "voice_087",
            "ecc_feel_stretch": "voice_088",
            "ecc_nice_slow": "voice_089",
            "ecc_keep_tension": "voice_090",
            "ecc_resist": "voice_091",
            "ecc_smooth": "voice_092",
            
            // Concentric cues
            "con_push_now": "voice_093",
            "con_drive_up": "voice_094",
            "con_squeeze": "voice_095",
            "con_power": "voice_096",
            "con_strong_push": "voice_097",
            "con_keep_pushing": "voice_098",
            "con_contract": "voice_099",
            
            // Final negative cues
            "final_negative": "voice_100",
            "final_all_way": "voice_101",
            "final_max_tension": "voice_102",
            "final_fight": "voice_103",
            "final_slow": "voice_104",
            "final_control": "voice_105",
            "final_dont_give_up": "voice_106",
            "final_last_push": "voice_107",
            
            // Encouragement
            "enc_great_work": "voice_108",
            "enc_you_got_this": "voice_109",
            "enc_stay_strong": "voice_110",
            "enc_keep_going": "voice_111",
            "enc_excellent_form": "voice_113",
            "enc_thats_it": "voice_114",
            "enc_perfect": "voice_115",
            "enc_well_done": "voice_116",
            "enc_fantastic": "voice_117",
            "enc_one_more": "voice_118",
            "enc_push_through": "voice_119",
            "enc_doing_great": "voice_120",
            "enc_strong_finish": "voice_121",
            
            // Positioning cues
            "cue_get_position": "voice_081",
            "cue_starting_weight": "voice_082",
            "cue_grip": "voice_083",
            "cue_posture": "voice_084",
            "cue_control": "voice_085",
            
            // Exercises (including aliases for different naming conventions)
            "ex_leg_press": "voice_139",
            "ex_lat_pulldown": "voice_140",
            "ex_pulldown": "voice_140",  // Alias for lat pulldown
            "ex_chest_press": "voice_141",
            "ex_shoulder_press": "voice_142",
            "ex_overhead_press": "voice_142",  // Alias for shoulder press
            "ex_leg_curl": "voice_143",
            "ex_bicep_curl": "voice_144",
            "ex_tricep_extension": "voice_145",
            "ex_calf_raise": "voice_146",
            "ex_leg_extension": "voice_147",
            "ex_seated_row": "voice_148",
            "ex_incline_press": "voice_149",
            "ex_lateral_raise": "voice_150",
            "ex_shrug": "voice_151",
            "ex_ab_crunch": "voice_152",
            "ex_back_extension": "voice_153",
        ]
        
        mappings = defaults
        print("[SoundMappingManager] Loaded \(defaults.count) hardcoded mappings")
        saveMappings()
    }
    
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        loadDefaultMappings()
    }
    
    private func saveMappings() {
        if let encoded = try? JSONEncoder().encode(mappings) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    func getFilename(for key: String) -> String? {
        return mappings[key]
    }
    
    func setMapping(key: String, filename: String) {
        mappings[key] = filename
    }
    
    func getAvailableAudioFiles() -> [String] {
        var files: [String] = []
        
        // Check for ElevenLabs-named files in Audio directory
        if let audioURL = Bundle.main.url(forResource: "Audio", withExtension: nil),
           let contents = try? FileManager.default.contentsOfDirectory(at: audioURL, includingPropertiesForKeys: nil) {
            for url in contents where url.pathExtension == "mp3" {
                files.append(url.deletingPathExtension().lastPathComponent)
            }
        }
        
        // Also check root bundle for mp3 files
        if let bundlePath = Bundle.main.resourcePath,
           let contents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) {
            for file in contents where file.hasSuffix(".mp3") {
                let name = file.replacingOccurrences(of: ".mp3", with: "")
                if !files.contains(name) {
                    files.append(name)
                }
            }
        }
        
        return files.sorted()
    }
    
    // List of keys we support (based on AudioManager.AudioFiles)
    static let supportedKeys: [(String, String)] = [
        // Countdown numbers
        ("Count: 1", "count_1"),
        ("Count: 2", "count_2"),
        ("Count: 3", "count_3"),
        ("Count: 4", "count_4"),
        ("Count: 5", "count_5"),
        ("Count: 6", "count_6"),
        ("Count: 7", "count_7"),
        ("Count: 8", "count_8"),
        ("Count: 9", "count_9"),
        ("Count: 10", "count_10"),
        
        // Workout events
        ("Workout Begin", "workout_begin"),
        ("Workout Complete", "workout_complete"),
        ("Workout Crushed", "workout_crushed"),
        
        // Rest events
        ("Rest Starting", "rest_starting"),
        ("Rest Breathe", "rest_breathe"),
        ("Rest Complete", "rest_complete"),
        ("Rest Next Coming", "rest_next_coming"),
        ("Rest Get Ready", "rest_get_ready"),
        
        // Time cues
        ("Halfway", "time_halfway"),
        ("Almost There", "time_almost"),
        ("5 Seconds", "time_5_sec"),
        ("10 Seconds", "time_10_sec"),
        
        // Phase cues
        ("Phase - Eccentric", "phase_eccentric"),
        ("Phase - Concentric", "phase_concentric"),
        ("Phase - Complete", "phase_complete"),
        ("Phase - Get Ready", "phase_get_ready"),
        
        // Encouragement
        ("Encouragement", "enc_great_work"),
        
        // MACHINE EXERCISES - Chest
        ("Exercise: Chest Press", "ex_chest_press"),
        ("Exercise: Incline Press", "ex_incline_press"),
        ("Exercise: Decline Press", "ex_decline_press"),
        ("Exercise: Pec Deck", "ex_pec_deck"),
        ("Exercise: Chest Fly", "ex_chest_fly"),
        ("Exercise: Cable Crossover", "ex_cable_crossover"),
        
        // MACHINE EXERCISES - Back
        ("Exercise: Lat Pulldown", "ex_lat_pulldown"),
        ("Exercise: Seated Row", "ex_seated_row"),
        ("Exercise: Cable Row", "ex_cable_row"),
        ("Exercise: Machine Row", "ex_machine_row"),
        ("Exercise: Back Extension", "ex_back_extension"),
        
        // MACHINE EXERCISES - Shoulders
        ("Exercise: Shoulder Press", "ex_shoulder_press"),
        ("Exercise: Lateral Raise", "ex_lateral_raise"),
        ("Exercise: Rear Delt", "ex_rear_delt"),
        ("Exercise: Reverse Pec Deck", "ex_reverse_pec_deck"),
        ("Exercise: Face Pull", "ex_face_pull"),
        
        // MACHINE EXERCISES - Arms
        ("Exercise: Bicep Curl", "ex_bicep_curl"),
        ("Exercise: Preacher Curl", "ex_preacher_curl"),
        ("Exercise: Cable Curl", "ex_cable_curl"),
        ("Exercise: Tricep Extension", "ex_tricep_extension"),
        ("Exercise: Tricep Pushdown", "ex_tricep_pushdown"),
        
        // MACHINE EXERCISES - Legs
        ("Exercise: Leg Press", "ex_leg_press"),
        ("Exercise: Leg Extension", "ex_leg_extension"),
        ("Exercise: Leg Curl", "ex_leg_curl"),
        ("Exercise: Seated Leg Curl", "ex_seated_leg_curl"),
        ("Exercise: Lying Leg Curl", "ex_lying_leg_curl"),
        ("Exercise: Hack Squat", "ex_hack_squat"),
        ("Exercise: Hip Thrust", "ex_hip_thrust"),
        
        // MACHINE EXERCISES - Calves
        ("Exercise: Calf Raise", "ex_calf_raise"),
        ("Exercise: Seated Calf Raise", "ex_seated_calf_raise"),
        
        // MACHINE EXERCISES - Hips/Glutes
        ("Exercise: Hip Adduction", "ex_hip_adduction"),
        ("Exercise: Hip Abduction", "ex_hip_abduction"),
        ("Exercise: Glute Kickback", "ex_glute_kickback"),
        
        // MACHINE EXERCISES - Core
        ("Exercise: Ab Crunch", "ex_ab_crunch"),
        ("Exercise: Cable Crunch", "ex_cable_crunch"),
        ("Exercise: Torso Rotation", "ex_torso_rotation"),
    ]
}
