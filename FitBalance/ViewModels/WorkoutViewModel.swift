import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published var muscleStats: [MuscleGroup: MuscleStats] = [:]
    @Published var currentPlan: WorkoutPlan?
    @Published var selectedMuscles: Set<MuscleGroup> = []
    @Published var anytimeFilterEnabled: Bool = false

    private let planStorageKey = "fitbalance_current_plan"

    func refreshStats(sessions: [WorkoutSession]) {
        muscleStats = StatsCalculator.calculate(from: sessions)
    }

    func toggleMuscle(_ muscle: MuscleGroup) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }

    func clearSelection() {
        selectedMuscles.removeAll()
    }

    func savePlan(_ plan: WorkoutPlan) {
        currentPlan = plan
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: planStorageKey)
        }
    }

    func loadSavedPlan() {
        guard let data = UserDefaults.standard.data(forKey: planStorageKey),
              let plan = try? JSONDecoder().decode(WorkoutPlan.self, from: data)
        else { return }
        currentPlan = plan
    }

    func deviationColor(for muscle: MuscleGroup) -> some View {
        let dev = muscleStats[muscle]?.deviation ?? 50
        return StatsCalculator.colorForDeviation(dev)
    }

    func exercises(for muscles: [MuscleGroup]) -> [Exercise] {
        var result: [Exercise] = []
        for muscle in muscles {
            let exercises = ExerciseDatabase.exercises(for: muscle, anytimeOnly: anytimeFilterEnabled)
            result.append(contentsOf: exercises)
        }
        return result.removingDuplicates()
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
