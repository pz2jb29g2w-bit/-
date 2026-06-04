import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: WorkoutViewModel

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var session: WorkoutSession?
    @State private var showExercisePicker = false
    @State private var notes = ""
    @State private var isSaved = false

    private var todaySession: WorkoutSession? {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let s = session ?? todaySession {
                    sessionEditor(s)
                } else {
                    startSessionPrompt
                }
            }
            .navigationTitle("トレーニング記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let s = session ?? todaySession {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showExercisePicker = true
                        } label: {
                            Label("種目追加", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("保存") { saveSession(s) }
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                }
            }
            .overlay {
                if isSaved {
                    savedOverlay
                }
            }
        }
    }

    // MARK: - Session editor

    private func sessionEditor(_ s: WorkoutSession) -> some View {
        List {
            Section("日時") {
                DatePicker("日付", selection: Binding(
                    get: { s.date },
                    set: { s.date = $0 }
                ), displayedComponents: .date)
            }

            ForEach(s.exerciseLogs) { log in
                exerciseSection(log: log, session: s)
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(s.exerciseLogs[i]) }
            }

            Section("メモ") {
                TextField("自由記入", text: Binding(
                    get: { s.notes },
                    set: { s.notes = $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }
        }
    }

    private func exerciseSection(log: ExerciseLog, session: WorkoutSession) -> some View {
        Section {
            ForEach(log.sets) { set in
                setRow(set: set)
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(log.sets[i]) }
            }

            Button {
                let newSet = WorkoutSet()
                newSet.log = log
                log.sets.append(newSet)
                modelContext.insert(newSet)
            } label: {
                Label("セットを追加", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        } header: {
            HStack {
                Text(log.exerciseName).fontWeight(.semibold)
                Spacer()
                Text(log.primaryMuscleGroups.map { $0.shortName }.joined(separator: " · "))
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func setRow(set: WorkoutSet) -> some View {
        HStack(spacing: 12) {
            Button {
                set.isCompleted.toggle()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Text("重量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                weightField(value: Binding(
                    get: { set.weight },
                    set: { set.weight = $0 }
                ))
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                repsField(value: Binding(
                    get: { set.reps },
                    set: { set.reps = $0 }
                ))
                Text("回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(String(format: "%.0fkg", set.volume))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func weightField(value: Binding<Double>) -> some View {
        TextField("0", value: value, format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 48)
    }

    private func repsField(value: Binding<Int>) -> some View {
        TextField("0", value: value, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 36)
    }

    // MARK: - Start prompt

    private var startSessionPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("今日のトレーニングを開始")
                .font(.title2)
                .fontWeight(.semibold)
            Text("種目を追加して記録を始めましょう")
                .foregroundStyle(.secondary)
            Button("セッションを開始") {
                let newSession = WorkoutSession()
                modelContext.insert(newSession)
                session = newSession
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Saved overlay

    private var savedOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("保存しました")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green.gradient)
            .clipShape(Capsule())
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        let target = session ?? todaySession
        guard let s = target else {
            let newSession = WorkoutSession()
            modelContext.insert(newSession)
            session = newSession
            let log = ExerciseLog(exercise: exercise)
            log.session = newSession
            newSession.exerciseLogs.append(log)
            modelContext.insert(log)
            let firstSet = WorkoutSet()
            firstSet.log = log
            log.sets.append(firstSet)
            modelContext.insert(firstSet)
            return
        }

        let log = ExerciseLog(exercise: exercise)
        log.session = s
        s.exerciseLogs.append(log)
        modelContext.insert(log)
        let firstSet = WorkoutSet()
        firstSet.log = log
        log.sets.append(firstSet)
        modelContext.insert(firstSet)
    }

    private func saveSession(_ s: WorkoutSession) {
        try? modelContext.save()
        viewModel.refreshStats(sessions: sessions)
        withAnimation {
            isSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { isSaved = false }
        }
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: WorkoutViewModel

    @State private var searchText = ""
    @State private var selectedMuscleFilter: MuscleGroup?

    private var filtered: [Exercise] {
        var list = ExerciseDatabase.all
        if viewModel.anytimeFilterEnabled {
            list = list.filter { $0.isAnytimeCompatible }
        }
        if let muscle = selectedMuscleFilter {
            list = list.filter { $0.primaryMuscles.contains(muscle) }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                muscleFilterScroll

                List(filtered) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "種目を検索")
            .navigationTitle("種目を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("エニタイムのみ", isOn: $viewModel.anytimeFilterEnabled)
                        .toggleStyle(.button)
                        .controlSize(.small)
                }
            }
        }
    }

    private var muscleFilterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "すべて", muscle: nil)
                ForEach(MuscleGroup.allCases) { muscle in
                    filterChip(label: muscle.shortName, muscle: muscle)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, muscle: MuscleGroup?) -> some View {
        let isSelected = selectedMuscleFilter == muscle
        return Button {
            selectedMuscleFilter = isSelected ? nil : muscle
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name).font(.body)
            HStack {
                Text(exercise.primaryMuscles.map { $0.shortName }.joined(separator: "・"))
                    .font(.caption)
                    .foregroundStyle(.tint)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(exercise.equipment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if exercise.isAnytimeCompatible {
                    Text("AT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}
