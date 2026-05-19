import Foundation
import SwiftUI

struct MuscleStats {
    let muscleGroup: MuscleGroup
    let totalVolume: Double
    let sessionCount: Int
    let lastWorkoutDate: Date?
    var deviation: Double

    var deviationColor: Color { StatsCalculator.colorForDeviation(deviation) }

    var deviationLabel: String {
        switch deviation {
        case ..<40:  return "不足"
        case 40...60: return "バランス良好"
        default:     return "十分"
        }
    }

    var daysSinceLastWorkout: Int? {
        guard let last = lastWorkoutDate else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }
}

enum StatsCalculator {
    static func calculate(from sessions: [WorkoutSession], windowDays: Int = 30) -> [MuscleGroup: MuscleStats] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: Date()) ?? Date()
        let recent = sessions.filter { $0.date >= cutoff }

        var volumeMap:   [MuscleGroup: Double] = [:]
        var countMap:    [MuscleGroup: Int] = [:]
        var lastDateMap: [MuscleGroup: Date] = [:]

        for session in recent {
            for log in session.exerciseLogs {
                let vol = log.sets.reduce(0.0) { $0 + $1.volume }
                for muscle in log.primaryMuscleGroups {
                    volumeMap[muscle, default: 0] += vol
                    countMap[muscle, default: 0] += 1
                    if lastDateMap[muscle] == nil || session.date > lastDateMap[muscle]! {
                        lastDateMap[muscle] = session.date
                    }
                }
            }
        }

        // Ensure every muscle group has an entry (even if zero)
        for group in MuscleGroup.allCases where volumeMap[group] == nil {
            volumeMap[group] = 0
        }

        let allVolumes = MuscleGroup.allCases.map { volumeMap[$0, default: 0] }
        let mean = allVolumes.reduce(0, +) / Double(allVolumes.count)
        let variance = allVolumes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(allVolumes.count)
        let stdDev = sqrt(variance)

        var result: [MuscleGroup: MuscleStats] = [:]
        for muscle in MuscleGroup.allCases {
            let vol = volumeMap[muscle, default: 0]
            let dev: Double = stdDev > 0 ? (vol - mean) / stdDev * 10 + 50 : 50
            result[muscle] = MuscleStats(
                muscleGroup: muscle,
                totalVolume: vol,
                sessionCount: countMap[muscle, default: 0],
                lastWorkoutDate: lastDateMap[muscle],
                deviation: max(20, min(80, dev))
            )
        }
        return result
    }

    static func colorForDeviation(_ deviation: Double) -> Color {
        if deviation < 40 {
            let t = (40 - deviation) / 20
            return Color(red: 0.15, green: 0.3 + t * 0.1, blue: min(1.0, 0.8 + t * 0.2))
        } else if deviation <= 60 {
            return Color(red: 0.2, green: 0.75, blue: 0.3)
        } else {
            let t = min(1.0, (deviation - 60) / 20)
            return Color(red: min(1.0, 0.85 + t * 0.15), green: max(0, 0.3 - t * 0.25), blue: 0.1)
        }
    }

    // Muscles that most need training (deviation < threshold)
    static func weakMuscles(from stats: [MuscleGroup: MuscleStats], threshold: Double = 48) -> [MuscleGroup] {
        stats.values
            .filter { $0.deviation < threshold }
            .sorted { $0.deviation < $1.deviation }
            .map { $0.muscleGroup }
    }
}
