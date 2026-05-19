import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject private var viewModel: WorkoutViewModel
    @EnvironmentObject private var planGenerator: PlanGeneratorViewModel

    @State private var showGeneratorSheet = false
    @State private var expandedDayId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if let plan = viewModel.currentPlan {
                    planContent(plan)
                } else {
                    emptyState
                }
            }
            .navigationTitle("トレーニングプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGeneratorSheet = true
                    } label: {
                        Label("新しいプラン", systemImage: "wand.and.stars")
                    }
                }
            }
            .sheet(isPresented: $showGeneratorSheet) {
                NavigationStack {
                    PlanGenerationOptionsView(
                        selectedMuscles: [],
                        onGenerate: { plan in
                            viewModel.savePlan(plan)
                            showGeneratorSheet = false
                        }
                    )
                    .navigationTitle("プランを作成")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる") { showGeneratorSheet = false }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Plan content

    private func planContent(_ plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                planHeader(plan)

                ForEach(plan.days) { day in
                    dayCard(day: day, isExpanded: expandedDayId == day.id)
                }
            }
            .padding()
        }
    }

    private func planHeader(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label("週\(plan.daysPerWeek)日", systemImage: "calendar")
                Label("\(plan.days.reduce(0) { $0 + $1.exercises.count })種目", systemImage: "dumbbell")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !plan.focusMuscles.isEmpty {
                HStack {
                    Text("強化対象：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(plan.focusMuscles.prefix(4)) { muscle in
                        Text(muscle.shortName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }

            Text("作成日：\(plan.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayCard(day: WorkoutDay, isExpanded: Bool) -> some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    expandedDayId = isExpanded ? nil : day.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.label)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(day.targetMuscles.map { $0.shortName }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(day.exercises.count)種目")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                VStack(spacing: 0) {
                    ForEach(day.exercises) { planned in
                        plannedExerciseRow(planned)
                        if planned.id != day.exercises.last?.id {
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func plannedExerciseRow(_ planned: PlannedExercise) -> some View {
        let exercise = ExerciseDatabase.all.first { $0.id.uuidString == planned.exerciseId }

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(planned.exerciseName)
                    .font(.subheadline)
                HStack(spacing: 6) {
                    Text(planned.equipment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if planned.suggestedWeight > 0 {
                        Text("目安: \(Int(planned.suggestedWeight))kg")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(planned.sets)セット × \(planned.reps)回")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(planned.targetMuscles.map { $0.shortName }.joined(separator: "・"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let ex = exercise {
                NavigationLink(destination: ExerciseDetailView(exercise: ex)) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("まだプランがありません")
                .font(.title2)
                .fontWeight(.semibold)
            Text("ボディマップで部位を選択するか、\nここからプランを自動生成できます")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showGeneratorSheet = true
            } label: {
                Label("プランを生成", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
