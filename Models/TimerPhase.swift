import Foundation

enum TimerPhase: String, CaseIterable {
    case prep = "Get Ready"
    case positioning = "Get Into Position"
    case eccentric = "Eccentric"
    case concentric = "Concentric"
    case finalEccentric = "Final Eccentric"
    case complete = "Complete"
    case rest = "Rest"

    var defaultDuration: Int {
        switch self {
        case .prep: return 10
        case .positioning: return 5
        case .eccentric: return 30
        case .concentric: return 20
        case .finalEccentric: return 40
        case .complete: return 0
        case .rest: return 90
        }
    }

    var color: String {
        switch self {
        case .prep, .positioning: return "gray"
        case .eccentric: return "blue"
        case .concentric: return "green"
        case .finalEccentric: return "orange"
        case .complete: return "gold"
        case .rest: return "purple"
        }
    }

    var audioFileName: String {
        switch self {
        case .prep: return "phase_get_ready"
        case .positioning: return "phase_position"
        case .eccentric: return "phase_eccentric"
        case .concentric: return "phase_concentric"
        case .finalEccentric: return "phase_final_eccentric"
        case .complete: return "phase_complete"
        case .rest: return "phase_rest"
        }
    }
    
    /// Human-readable name for Live Activity display
    var displayName: String {
        switch self {
        case .prep: return "Get Ready"
        case .positioning: return "Position"
        case .eccentric: return "Lower"
        case .concentric: return "Push"
        case .finalEccentric: return "Final Negative"
        case .complete: return "Complete"
        case .rest: return "Rest"
        }
    }
}

struct PhaseSettings: Codable {
    var prepDuration: Int = 10
    var positioningDuration: Int = 5
    var eccentricDuration: Int = 30
    var concentricDuration: Int = 20
    var finalEccentricDuration: Int = 40
    var restDuration: Int = 90

    func duration(for phase: TimerPhase) -> Int {
        switch phase {
        case .prep: return prepDuration
        case .positioning: return positioningDuration
        case .eccentric: return eccentricDuration
        case .concentric: return concentricDuration
        case .finalEccentric: return finalEccentricDuration
        case .rest: return restDuration
        case .complete: return 0
        }
    }
}
