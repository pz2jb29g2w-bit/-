import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var planGenerator = PlanGeneratorViewModel()
    @Query private var sessions: [WorkoutSession]

    var body: some View {
        TabView {
            BodyMapView()
                .tabItem { Label("ボディマップ", systemImage: "figure.arms.open") }

            WorkoutLogView()
                .tabItem { Label("記録", systemImage: "plus.circle.fill") }

            WorkoutPlanView()
                .tabItem { Label("プラン", systemImage: "calendar") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "list.bullet") }
        }
        .environmentObject(viewModel)
        .environmentObject(planGenerator)
        .onAppear {
            viewModel.refreshStats(sessions: sessions)
            viewModel.loadSavedPlan()
        }
        .onChange(of: sessions.count) {
            viewModel.refreshStats(sessions: sessions)
        }
    }
}
