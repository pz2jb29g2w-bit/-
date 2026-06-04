import Foundation
import Combine

final class PlanGeneratorViewModel: ObservableObject {
    @Published var isGenerating: Bool = false

    // Generate a balanced plan given current stats and optional forced focus muscles
    func generatePlan(
        stats: [MuscleGroup: MuscleStats],
        daysPerWeek: Int = 3,
        focusOverride: [MuscleGroup] = [],
        anytimeOnly: Bool = false
    ) -> WorkoutPlan {
        isGenerating = true
        defer { isGenerating = false }

        let focus = focusOverride.isEmpty ? StatsCalculator.weakMuscles(from: stats) : focusOverride
        let split = buildSplit(for: daysPerWeek, focus: focus)

        let days = split.enumerated().map { (idx, muscleGroups) -> WorkoutDay in
            let label = dayLabel(index: idx, daysPerWeek: daysPerWeek)
            let exercises = selectExercises(for: muscleGroups, stats: stats, anytimeOnly: anytimeOnly)
            return WorkoutDay(label: label, exercises: exercises, targetMuscles: muscleGroups)
        }

        return WorkoutPlan(
            name: planName(daysPerWeek: daysPerWeek, focus: focus),
            days: days,
            focusMuscles: focus,
            daysPerWeek: daysPerWeek
        )
    }

    // MARK: - Private helpers

    private func buildSplit(for daysPerWeek: Int, focus: [MuscleGroup]) -> [[MuscleGroup]] {
        switch daysPerWeek {
        case 3:
            return threeDaySplit(focus: focus)
        case 4:
            return fourDaySplit(focus: focus)
        case 5:
            return fiveDaySplit(focus: focus)
        default:
            return threeDaySplit(focus: focus)
        }
    }

    private func threeDaySplit(focus: [MuscleGroup]) -> [[MuscleGroup]] {
        // Push / Pull / Legs
        var push: [MuscleGroup] = [.chest, .shoulders, .triceps]
        var pull: [MuscleGroup] = [.back, .biceps, .forearms]
        var legs: [MuscleGroup] = [.quads, .hamstrings, .glutes, .calves, .core]

        // Boost underdeveloped groups by moving them to the first slot of relevant day
        for m in focus.prefix(3) {
            if push.contains(m) { push = [m] + push.filter { $0 != m } }
            if pull.contains(m) { pull = [m] + pull.filter { $0 != m } }
            if legs.contains(m) { legs = [m] + legs.filter { $0 != m } }
        }
        return [push, pull, legs]
    }

    private func fourDaySplit(focus: [MuscleGroup]) -> [[MuscleGroup]] {
        // Upper A / Lower A / Upper B / Lower B
        let upperA: [MuscleGroup] = [.chest, .back, .core]
        let lowerA: [MuscleGroup] = [.quads, .hamstrings, .calves]
        let upperB: [MuscleGroup] = [.shoulders, .biceps, .triceps, .forearms]
        let lowerB: [MuscleGroup] = [.glutes, .hamstrings, .calves, .core]
        return [upperA, lowerA, upperB, lowerB]
    }

    private func fiveDaySplit(focus: [MuscleGroup]) -> [[MuscleGroup]] {
        // Bro split
        return [
            [.chest, .triceps],
            [.back, .biceps],
            [.shoulders, .forearms],
            [.quads, .calves],
            [.hamstrings, .glutes, .core],
        ]
    }

    private func selectExercises(
        for muscles: [MuscleGroup],
        stats: [MuscleGroup: MuscleStats],
        anytimeOnly: Bool
    ) -> [PlannedExercise] {
        var result: [PlannedExercise] = []
        for muscle in muscles.prefix(3) {
            let pool = ExerciseDatabase.exercises(for: muscle, anytimeOnly: anytimeOnly)
            guard !pool.isEmpty else { continue }

            // Pick up to 2 exercises per muscle group
            let picks = Array(pool.prefix(2))
            for exercise in picks {
                let (sets, reps) = recommendedVolume(for: exercise.difficulty,
                                                     deviation: stats[muscle]?.deviation ?? 50)
                let suggested = estimatedWeight(for: muscle)
                result.append(PlannedExercise(exercise: exercise,
                                             sets: sets,
                                             reps: reps,
                                             suggestedWeight: suggested))
            }
        }
        return result
    }

    private func recommendedVolume(for difficulty: Exercise.Difficulty, deviation: Double) -> (sets: Int, reps: Int) {
        // Under-trained muscles get higher volume
        let extraVolume = deviation < 45
        switch difficulty {
        case .beginner:
            return extraVolume ? (4, 12) : (3, 12)
        case .intermediate:
            return extraVolume ? (4, 10) : (3, 10)
        case .advanced:
            return extraVolume ? (5, 8)  : (4, 8)
        }
    }

    private func estimatedWeight(for muscle: MuscleGroup) -> Double {
        // Rough default starting weights in kg
        switch muscle {
        case .chest:      return 60
        case .back:       return 60
        case .shoulders:  return 30
        case .biceps:     return 15
        case .triceps:    return 20
        case .forearms:   return 10
        case .core:       return 0
        case .quads:      return 80
        case .hamstrings: return 50
        case .glutes:     return 60
        case .calves:     return 40
        }
    }

    private func dayLabel(index: Int, daysPerWeek: Int) -> String {
        let labels3 = ["Day 1: プッシュ（胸・肩・三頭）",
                       "Day 2: プル（背中・二頭）",
                       "Day 3: レッグス"]
        let labels4 = ["Day 1: 上半身 A",
                       "Day 2: 下半身 A",
                       "Day 3: 上半身 B",
                       "Day 4: 下半身 B"]
        let labels5 = ["Day 1: 胸・三頭",
                       "Day 2: 背中・二頭",
                       "Day 3: 肩・前腕",
                       "Day 4: 大腿四頭筋",
                       "Day 5: ハムストリング・臀部・腹筋"]

        switch daysPerWeek {
        case 3: return labels3[safe: index] ?? "Day \(index + 1)"
        case 4: return labels4[safe: index] ?? "Day \(index + 1)"
        case 5: return labels5[safe: index] ?? "Day \(index + 1)"
        default: return "Day \(index + 1)"
        }
    }

    private func planName(daysPerWeek: Int, focus: [MuscleGroup]) -> String {
        let topFocus = focus.prefix(2).map { $0.shortName }.joined(separator: "・")
        let suffix = topFocus.isEmpty ? "" : "（\(topFocus)強化）"
        return "週\(daysPerWeek)日プラン\(suffix)"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
