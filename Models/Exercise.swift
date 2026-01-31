import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let audioFileName: String
    var lastWeight: Double?
    var reachedFailure: Bool = false
    var isCompleted: Bool = false
    var isBodyweight: Bool = false  // For exercises like pull-ups, dips - track time only
    var lastDuration: Int?          // Duration in seconds for bodyweight exercises

    init(id: UUID = UUID(), name: String, iconName: String, audioFileName: String, lastWeight: Double? = nil, isBodyweight: Bool = false) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.audioFileName = audioFileName
        self.lastWeight = lastWeight
        self.isBodyweight = isBodyweight
    }
}

struct Workout: Identifiable, Codable {
    let id: UUID
    let name: String
    var exercises: [Exercise]

    init(id: UUID = UUID(), name: String = "Workout", exercises: [Exercise]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

extension Workout {
    static let defaultWorkout = Workout(
        name: "Full Body HIT",
        exercises: [
            Exercise(name: "Leg Press", iconName: "bicep_curl.png", audioFileName: "ex_leg_press"),
            Exercise(name: "Pulldown", iconName: "pull_up.png", audioFileName: "ex_pulldown"),
            Exercise(name: "Chest Press", iconName: "bench_press.png", audioFileName: "ex_chest_press"),
            Exercise(name: "Overhead Press", iconName: "overhead_press.png", audioFileName: "ex_overhead_press"),
            Exercise(name: "Seated Row", iconName: "barbell_row.png", audioFileName: "ex_seated_row"),
            Exercise(name: "Leg Curl", iconName: "lunge.png", audioFileName: "ex_leg_curl"),
            Exercise(name: "Bicep Curl", iconName: "tricep_extension.png", audioFileName: "ex_bicep_curl"),
            Exercise(name: "Tricep Extension", iconName: "lateral_raise.png", audioFileName: "ex_tricep_extension")
        ]
    )
}
