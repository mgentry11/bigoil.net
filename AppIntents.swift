import AppIntents
import SwiftUI

// MARK: - Shared Workout Manager for App Intents
class SharedWorkoutManager {
    static let shared = SharedWorkoutManager()
    weak var workoutManager: WorkoutManager?

    private init() {}
}

// MARK: - Siri Tip Views (show users what to say)
struct SiriTipBanner: View {
    let phrase: String
    let intent: any AppIntent
    @State private var showingTip = true

    var body: some View {
        if showingTip {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Say to Siri:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\"\(phrase)\"")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ThemeManager.shared.text)
                }

                Spacer()

                Button(action: { showingTip = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(ThemeManager.shared.card)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// Simple tip that shows what phrases work
struct QuickSiriTips: View {
    @AppStorage("hasSeenSiriTips") private var hasSeenTips = false
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed state - just a small hint
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    if !isExpanded {
                        Text("Tap for Siri voice commands")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Siri Voice Commands")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeManager.shared.text)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Say \"Hey Siri\" then:")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)

                    Text("Workouts")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.primary)
                    SiriPhraseRow(phrase: "Start workout with OneRepStrength", description: "Quick start")

                    Text("Any Exercise")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeManager.shared.primary)
                        .padding(.top, 8)
                    SiriPhraseRow(phrase: "OneRepStrength [exercise name]", description: "e.g. \"OneRepStrength Pec Deck\"")
                    SiriPhraseRow(phrase: "Start [exercise] with OneRepStrength", description: "e.g. \"Start Leg Press with OneRepStrength\"")
                }
                .padding()
                .background(ThemeManager.shared.card)
            }
        }
        .background(ThemeManager.shared.card)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SiriPhraseRow: View {
    let phrase: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\"Hey Siri, \(phrase)\"")
                    .font(.subheadline)
                    .foregroundColor(ThemeManager.shared.text)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

// MARK: - Start Workout Intent
struct QuickStartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Start Workout"
    static var description = IntentDescription("Start the first exercise of your current OneRepStrength workout")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let manager = SharedWorkoutManager.shared.workoutManager,
           let firstExercise = manager.currentWorkout.exercises.first {
            manager.startExercise(firstExercise)
        }
        return .result()
    }
}

// MARK: - Pause Workout Intent
struct PauseWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Workout"
    static var description = IntentDescription("Pause the current OneRepStrength workout timer")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        if let manager = SharedWorkoutManager.shared.workoutManager {
            manager.pauseTimer()
        }
        return .result()
    }
}

// MARK: - Resume Workout Intent
struct ResumeWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Workout"
    static var description = IntentDescription("Resume the current OneRepStrength workout timer")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let manager = SharedWorkoutManager.shared.workoutManager {
            manager.resumeTimer()
        }
        return .result()
    }
}

// MARK: - Skip Phase Intent
struct SkipPhaseIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip to Next Phase"
    static var description = IntentDescription("Skip to the next phase in your OneRepStrength workout")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        if let manager = SharedWorkoutManager.shared.workoutManager {
            manager.skipPhase()
        }
        return .result()
    }
}

// MARK: - Exercise Enum for Siri (Weight Machine exercises)
enum ExerciseType: String, AppEnum {
    // Default Workout A exercises
    case legPress = "Leg Press"
    case pulldown = "Pulldown"
    case chestPress = "Chest Press"
    case overheadPress = "Overhead Press"
    case legCurlA = "Leg Curl (Workout A)"
    case bicepCurl = "Bicep Curl"
    case tricepExtension = "Tricep Extension"
    case calfRaise = "Calf Raise"
    // Default Workout B exercises
    case legExtension = "Leg Extension"
    case seatedRow = "Seated Row"
    case inclinePress = "Incline Press"
    case lateralRaise = "Lateral Raise"
    case legCurlB = "Leg Curl (Workout B)"
    case shrug = "Shrug"
    case abCrunch = "Ab Crunch"
    case backExtension = "Back Extension"
    // Chest machines
    case pecDeck = "Pec Deck"
    case chestFly = "Chest Fly"
    case declinePress = "Decline Press"
    case convergingChestPress = "Converging Chest Press"
    // Back machines
    case latPulldown = "Lat Pulldown"
    case cableRow = "Cable Row"
    case lowRow = "Low Row"
    case highRow = "High Row"
    case tBar = "T-Bar Row"
    case assistedPullup = "Assisted Pullup"
    case rearDeltMachine = "Rear Delt Machine"
    // Shoulder machines
    case shoulderPress = "Shoulder Press"
    case lateralRaiseMachine = "Lateral Raise Machine"
    case reverseFly = "Reverse Fly"
    // Arm machines
    case preacherCurl = "Preacher Curl"
    case machineCurl = "Machine Curl"
    case tricepPushdown = "Tricep Pushdown"
    case assistedDip = "Assisted Dip"
    case wristCurl = "Wrist Curl"
    // Leg machines
    case hackSquat = "Hack Squat"
    case legCurl = "Leg Curl"
    case seatedLegCurl = "Seated Leg Curl"
    case lyingLegCurl = "Lying Leg Curl"
    case hipAbduction = "Hip Abduction"
    case hipAdduction = "Hip Adduction"
    case gluteKickback = "Glute Kickback"
    case hipExtension = "Hip Extension"
    case standingCalfRaise = "Standing Calf Raise"
    case seatedCalfRaise = "Seated Calf Raise"
    case innerThigh = "Inner Thigh"
    case outerThigh = "Outer Thigh"
    // Core machines
    case abdominalMachine = "Abdominal Machine"
    case rotaryTorso = "Rotary Torso"
    case hyperextension = "Hyperextension"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Exercise"

    static var caseDisplayRepresentations: [ExerciseType: DisplayRepresentation] = [
        // Default exercises
        .legPress: "Leg Press",
        .pulldown: "Pulldown",
        .chestPress: "Chest Press",
        .overheadPress: "Overhead Press",
        .legCurlA: "Leg Curl (Workout A)",
        .bicepCurl: "Bicep Curl",
        .tricepExtension: "Tricep Extension",
        .calfRaise: "Calf Raise",
        .legExtension: "Leg Extension",
        .seatedRow: "Seated Row",
        .inclinePress: "Incline Press",
        .lateralRaise: "Lateral Raise",
        .legCurlB: "Leg Curl (Workout B)",
        .shrug: "Shrug",
        .abCrunch: "Ab Crunch",
        .backExtension: "Back Extension",
        // Chest machines
        .pecDeck: "Pec Deck",
        .chestFly: "Chest Fly",
        .declinePress: "Decline Press",
        .convergingChestPress: "Converging Chest Press",
        // Back machines
        .latPulldown: "Lat Pulldown",
        .cableRow: "Cable Row",
        .lowRow: "Low Row",
        .highRow: "High Row",
        .tBar: "T-Bar Row",
        .assistedPullup: "Assisted Pullup",
        .rearDeltMachine: "Rear Delt Machine",
        // Shoulder machines
        .shoulderPress: "Shoulder Press",
        .lateralRaiseMachine: "Lateral Raise Machine",
        .reverseFly: "Reverse Fly",
        // Arm machines
        .preacherCurl: "Preacher Curl",
        .machineCurl: "Machine Curl",
        .tricepPushdown: "Tricep Pushdown",
        .assistedDip: "Assisted Dip",
        .wristCurl: "Wrist Curl",
        // Leg machines
        .hackSquat: "Hack Squat",
        .legCurl: "Leg Curl",
        .seatedLegCurl: "Seated Leg Curl",
        .lyingLegCurl: "Lying Leg Curl",
        .hipAbduction: "Hip Abduction",
        .hipAdduction: "Hip Adduction",
        .gluteKickback: "Glute Kickback",
        .hipExtension: "Hip Extension",
        .standingCalfRaise: "Standing Calf Raise",
        .seatedCalfRaise: "Seated Calf Raise",
        .innerThigh: "Inner Thigh",
        .outerThigh: "Outer Thigh",
        // Core machines
        .abdominalMachine: "Abdominal Machine",
        .rotaryTorso: "Rotary Torso",
        .hyperextension: "Hyperextension"
    ]

    // Map to actual exercise name
    var exerciseName: String {
        switch self {
        case .legCurlA, .legCurlB: return "Leg Curl"
        default: return rawValue.replacingOccurrences(of: " (Workout A)", with: "").replacingOccurrences(of: " (Workout B)", with: "")
        }
    }

}

// MARK: - Start Specific Exercise Intent (Enum-based for default exercises)
struct StartExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Exercise"
    static var description = IntentDescription("Start a specific exercise in OneRepStrength")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Exercise")
    var exercise: ExerciseType

    @MainActor
    func perform() async throws -> some IntentResult {
        if let manager = SharedWorkoutManager.shared.workoutManager {
            let exerciseName = exercise.exerciseName
            if let foundExercise = manager.currentWorkout.exercises.first(where: { $0.name == exerciseName }) {
                manager.startExercise(foundExercise)
            }
        }
        return .result()
    }
}

// Note: String-based intents cannot be used with AppShortcut phrases
// Only AppEnum and AppEntity parameters work with Siri shortcuts

// MARK: - Individual Exercise Intents (for direct Siri phrases)

struct StartLegPressIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Leg Press"
    static var description = IntentDescription("Start Leg Press exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Leg Press")
        return .result()
    }
}

struct StartPulldownIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Pulldown"
    static var description = IntentDescription("Start Pulldown exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Pulldown")
        return .result()
    }
}

struct StartChestPressIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Chest Press"
    static var description = IntentDescription("Start Chest Press exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Chest Press")
        return .result()
    }
}

struct StartOverheadPressIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Overhead Press"
    static var description = IntentDescription("Start Overhead Press exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Overhead Press")
        return .result()
    }
}

struct StartLegCurlIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Leg Curl"
    static var description = IntentDescription("Start Leg Curl exercise from current workout")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Start Leg Curl from current workout (doesn't switch workouts)
        await startExerciseInCurrentWorkout(named: "Leg Curl")
        return .result()
    }
}



struct StartBicepCurlIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Bicep Curl"
    static var description = IntentDescription("Start Bicep Curl exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Bicep Curl")
        return .result()
    }
}

struct StartTricepExtensionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tricep Extension"
    static var description = IntentDescription("Start Tricep Extension exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Tricep Extension")
        return .result()
    }
}

struct StartCalfRaiseIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Calf Raise"
    static var description = IntentDescription("Start Calf Raise exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Calf Raise")
        return .result()
    }
}

struct StartLegExtensionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Leg Extension"
    static var description = IntentDescription("Start Leg Extension exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Leg Extension")
        return .result()
    }
}

struct StartSeatedRowIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Seated Row"
    static var description = IntentDescription("Start Seated Row exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Seated Row")
        return .result()
    }
}

struct StartInclinePressIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Incline Press"
    static var description = IntentDescription("Start Incline Press exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Incline Press")
        return .result()
    }
}

struct StartLateralRaiseIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Lateral Raise"
    static var description = IntentDescription("Start Lateral Raise exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Lateral Raise")
        return .result()
    }
}

struct StartShrugIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Shrug"
    static var description = IntentDescription("Start Shrug exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Shrug")
        return .result()
    }
}

struct StartAbCrunchIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Ab Crunch"
    static var description = IntentDescription("Start Ab Crunch exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Ab Crunch")
        return .result()
    }
}

struct StartBackExtensionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Back Extension"
    static var description = IntentDescription("Start Back Extension exercise")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await startExercise(named: "Back Extension")
        return .result()
    }
}

@MainActor
func startExercise(named exerciseName: String) async {
    guard let manager = SharedWorkoutManager.shared.workoutManager else { return }
    if let foundExercise = manager.currentWorkout.exercises.first(where: { $0.name == exerciseName }) {
        manager.startExercise(foundExercise)
    }
}

@MainActor
func startExerciseInCurrentWorkout(named exerciseName: String) async {
    guard let manager = SharedWorkoutManager.shared.workoutManager else { return }
    if let foundExercise = manager.currentWorkout.exercises.first(where: { $0.name == exerciseName }) {
        manager.startExercise(foundExercise)
    }
}

// MARK: - App Shortcuts Provider (Apple limits to 10 shortcuts max)
struct OneRepStrengthShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickStartWorkoutIntent(),
            phrases: [
                "Start workout with \(.applicationName)",
                "\(.applicationName) quick start",
                "Open \(.applicationName)",
                "Start my workout with \(.applicationName)"
            ],
            shortTitle: "Start Workout",
            systemImageName: "play.fill"
        )

        AppShortcut(
            intent: StartExerciseIntent(),
            phrases: [
                "\(.applicationName) \(\.$exercise)"
            ],
            shortTitle: "Start Exercise",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: StartLegPressIntent(),
            phrases: [
                "Start Leg Press with \(.applicationName)",
                "\(.applicationName) Leg Press"
            ],
            shortTitle: "Leg Press",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: StartChestPressIntent(),
            phrases: [
                "Start Chest Press with \(.applicationName)",
                "\(.applicationName) Chest Press"
            ],
            shortTitle: "Chest Press",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: StartPulldownIntent(),
            phrases: [
                "Start Pulldown with \(.applicationName)",
                "\(.applicationName) Pulldown"
            ],
            shortTitle: "Pulldown",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: StartSeatedRowIntent(),
            phrases: [
                "Start Seated Row with \(.applicationName)",
                "\(.applicationName) Seated Row"
            ],
            shortTitle: "Seated Row",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: StartLegCurlIntent(),
            phrases: [
                "Start Leg Curl with \(.applicationName)",
                "\(.applicationName) Leg Curl"
            ],
            shortTitle: "Leg Curl",
            systemImageName: "figure.strengthtraining.traditional"
        )
    }
}
