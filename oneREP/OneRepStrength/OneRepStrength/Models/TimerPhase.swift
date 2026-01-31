//
//  TimerPhase.swift
//  OneRepStrength
//
//  Timer phase states and configuration
//

import SwiftUI

enum TimerPhase: String, CaseIterable {
    case prep = "PREP"
    case positive = "POSITIVE"
    case hold = "HOLD"
    case negative = "NEGATIVE"
    case complete = "COMPLETE"
    case rest = "REST"
    
    var instruction: String {
        switch self {
        case .prep: return "Get Ready"
        case .positive: return "Slowly Lift Up"
        case .hold: return "Hold at Top"
        case .negative: return "Slowly Lower Down"
        case .complete: return "Log Your Weight"
        case .rest: return "Rest & Recover"
        }
    }
    
    var color: Color {
        switch self {
        case .prep: return .phasePrep
        case .positive: return .phasePositive
        case .hold: return .phaseStatic
        case .negative: return .phaseNegative
        case .complete: return .phaseComplete
        case .rest: return Color(red: 0.3, green: 0.35, blue: 0.45)
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .prep: return 5
        case .positive: return 10
        case .hold: return 10
        case .negative: return 10
        case .complete: return 0
        case .rest: return 90
        }
    }
    
    var next: TimerPhase? {
        switch self {
        case .prep: return .positive
        case .positive: return .hold
        case .hold: return .negative
        case .negative: return .complete
        case .complete: return nil
        case .rest: return nil
        }
    }
}
