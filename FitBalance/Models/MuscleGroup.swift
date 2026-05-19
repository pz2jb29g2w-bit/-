import Foundation
import SwiftUI

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest       = "胸"
    case back        = "背中"
    case shoulders   = "肩"
    case biceps      = "上腕二頭筋"
    case triceps     = "上腕三頭筋"
    case forearms    = "前腕"
    case core        = "腹筋・体幹"
    case quads       = "大腿四頭筋"
    case hamstrings  = "ハムストリング"
    case glutes      = "臀部"
    case calves      = "ふくらはぎ"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .chest:      return "胸"
        case .back:       return "背中"
        case .shoulders:  return "肩"
        case .biceps:     return "二頭"
        case .triceps:    return "三頭"
        case .forearms:   return "前腕"
        case .core:       return "腹筋"
        case .quads:      return "大腿"
        case .hamstrings: return "裏腿"
        case .glutes:     return "臀部"
        case .calves:     return "ふくらはぎ"
        }
    }

    var visibleInFront: Bool {
        switch self {
        case .chest, .shoulders, .biceps, .forearms, .core, .quads, .calves: return true
        case .back, .triceps, .hamstrings, .glutes: return false
        }
    }

    var visibleInBack: Bool {
        switch self {
        case .back, .shoulders, .triceps, .forearms, .hamstrings, .glutes, .calves: return true
        case .chest, .biceps, .core, .quads: return false
        }
    }

    // Normalized front-view rect in 200×440 body coordinate space
    var frontRects: [CGRect] {
        switch self {
        case .chest:
            return [CGRect(x: 60, y: 62, width: 37, height: 64),
                    CGRect(x: 103, y: 62, width: 37, height: 64)]
        case .shoulders:
            return [CGRect(x: 27, y: 56, width: 32, height: 46),
                    CGRect(x: 141, y: 56, width: 32, height: 46)]
        case .biceps:
            return [CGRect(x: 21, y: 100, width: 30, height: 62),
                    CGRect(x: 149, y: 100, width: 30, height: 62)]
        case .forearms:
            return [CGRect(x: 18, y: 165, width: 28, height: 92),
                    CGRect(x: 154, y: 165, width: 28, height: 92)]
        case .core:
            return [CGRect(x: 64, y: 130, width: 72, height: 118)]
        case .quads:
            return [CGRect(x: 58, y: 262, width: 38, height: 112),
                    CGRect(x: 104, y: 262, width: 38, height: 112)]
        case .calves:
            return [CGRect(x: 61, y: 382, width: 33, height: 53),
                    CGRect(x: 106, y: 382, width: 33, height: 53)]
        default:
            return []
        }
    }

    // Normalized back-view rect in 200×440 body coordinate space
    var backRects: [CGRect] {
        switch self {
        case .back:
            return [CGRect(x: 58, y: 58, width: 84, height: 148)]
        case .shoulders:
            return [CGRect(x: 27, y: 56, width: 32, height: 46),
                    CGRect(x: 141, y: 56, width: 32, height: 46)]
        case .triceps:
            return [CGRect(x: 21, y: 100, width: 30, height: 68),
                    CGRect(x: 149, y: 100, width: 30, height: 68)]
        case .forearms:
            return [CGRect(x: 18, y: 172, width: 28, height: 88),
                    CGRect(x: 154, y: 172, width: 28, height: 88)]
        case .glutes:
            return [CGRect(x: 58, y: 258, width: 38, height: 52),
                    CGRect(x: 104, y: 258, width: 38, height: 52)]
        case .hamstrings:
            return [CGRect(x: 58, y: 312, width: 38, height: 64),
                    CGRect(x: 104, y: 312, width: 38, height: 64)]
        case .calves:
            return [CGRect(x: 62, y: 382, width: 32, height: 54),
                    CGRect(x: 106, y: 382, width: 32, height: 54)]
        default:
            return []
        }
    }
}
