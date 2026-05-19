import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var notes: String
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]

    init(date: Date = Date(), notes: String = "") {
        self.date = date
        self.notes = notes
        self.exerciseLogs = []
    }

    var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }

    var muscleNames: [String] {
        let muscles = exerciseLogs.flatMap { $0.primaryMuscleGroups }
        return Array(Set(muscles)).map { $0.rawValue }
    }
}

@Model
final class ExerciseLog {
    var exerciseId: String
    var exerciseName: String
    var muscleGroupRawValues: [String]
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
    var session: WorkoutSession?

    var primaryMuscleGroups: [MuscleGroup] {
        muscleGroupRawValues.compactMap { MuscleGroup(rawValue: $0) }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    init(exercise: Exercise) {
        self.exerciseId = exercise.id.uuidString
        self.exerciseName = exercise.name
        self.muscleGroupRawValues = exercise.primaryMuscles.map { $0.rawValue }
        self.sets = []
    }
}

@Model
final class WorkoutSet {
    var reps: Int
    var weight: Double
    var isCompleted: Bool
    var log: ExerciseLog?

    var volume: Double { Double(reps) * weight }

    init(reps: Int = 10, weight: Double = 20, isCompleted: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }
}
