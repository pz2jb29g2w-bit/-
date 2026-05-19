import SwiftUI
import SwiftData

@main
struct FitBalanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, WorkoutSet.self])
    }
}
