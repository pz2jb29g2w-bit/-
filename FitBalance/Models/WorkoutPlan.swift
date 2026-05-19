import Foundation

struct WorkoutPlan: Identifiable, Codable {
    let id: UUID
    var name: String
    var days: [WorkoutDay]
    var focusMuscles: [MuscleGroup]
    var createdAt: Date
    var daysPerWeek: Int

    init(
        id: UUID = UUID(),
        name: String,
        days: [WorkoutDay],
        focusMuscles: [MuscleGroup] = [],
        daysPerWeek: Int = 3
    ) {
        self.id = id
        self.name = name
        self.days = days
        self.focusMuscles = focusMuscles
        self.createdAt = Date()
        self.daysPerWeek = daysPerWeek
    }
}

struct WorkoutDay: Identifiable, Codable {
    let id: UUID
    var label: String
    var exercises: [PlannedExercise]
    var targetMuscles: [MuscleGroup]

    init(
        id: UUID = UUID(),
        label: String,
        exercises: [PlannedExercise],
        targetMuscles: [MuscleGroup]
    ) {
        self.id = id
        self.label = label
        self.exercises = exercises
        self.targetMuscles = targetMuscles
    }
}

struct PlannedExercise: Identifiable, Codable {
    let id: UUID
    let exerciseName: String
    let exerciseId: String
    var sets: Int
    var reps: Int
    var suggestedWeight: Double
    var muscleGroupRawValues: [String]
    var equipment: String

    var targetMuscles: [MuscleGroup] {
        muscleGroupRawValues.compactMap { MuscleGroup(rawValue: $0) }
    }

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        sets: Int,
        reps: Int,
        suggestedWeight: Double = 0
    ) {
        self.id = id
        self.exerciseName = exercise.name
        self.exerciseId = exercise.id.uuidString
        self.sets = sets
        self.reps = reps
        self.suggestedWeight = suggestedWeight
        self.muscleGroupRawValues = exercise.primaryMuscles.map { $0.rawValue }
        self.equipment = exercise.equipment
    }
}
