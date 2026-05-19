import SwiftUI
import SwiftData

struct BodyMapView: View {
    @EnvironmentObject private var viewModel: WorkoutViewModel
    @EnvironmentObject private var planGenerator: PlanGeneratorViewModel

    @State private var showFront = true
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectionMode = false
    @State private var showPlanSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Front / Back toggle
                Picker("View", selection: $showFront) {
                    Text("前面").tag(true)
                    Text("背面").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectionMode {
                    selectionBanner
                }

                // Body map
                GeometryReader { geo in
                    bodyCanvas(in: geo.size)
                        .gesture(tapGesture(in: geo.size))
                }

                // Detail panel
                if let muscle = selectedMuscle {
                    muscleDetailPanel(muscle: muscle)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("ボディマップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selectionMode ? "完了" : "部位を選ぶ") {
                        withAnimation { selectionMode.toggle() }
                        if !selectionMode { viewModel.clearSelection() }
                    }
                }
            }
            .sheet(isPresented: $showPlanSheet) {
                planGenerationSheet
            }
            .animation(.easeInOut(duration: 0.2), value: selectedMuscle)
        }
    }

    // MARK: - Canvas

    private func bodyCanvas(in size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let scale = min(canvasSize.width / 200, canvasSize.height / 440)
            let xOff = (canvasSize.width - 200 * scale) / 2
            let yOff = max(12, (canvasSize.height - 440 * scale) / 2)

            func transformed(_ rect: CGRect) -> CGRect {
                CGRect(x: rect.minX * scale + xOff,
                       y: rect.minY * scale + yOff,
                       width: rect.width * scale,
                       height: rect.height * scale)
            }

            // Body silhouette (light background)
            drawSilhouette(ctx: ctx, scale: scale, xOff: xOff, yOff: yOff)

            // Muscle group regions
            for muscle in MuscleGroup.allCases {
                let visible = showFront ? muscle.visibleInFront : muscle.visibleInBack
                guard visible else { continue }

                let rects = showFront ? muscle.frontRects : muscle.backRects
                let dev = viewModel.muscleStats[muscle]?.deviation ?? 50
                let selected = viewModel.selectedMuscles.contains(muscle)
                let highlighted = selectedMuscle == muscle

                let baseColor = StatsCalculator.colorForDeviation(dev)
                let fillAlpha: Double = highlighted ? 0.9 : (selected ? 0.85 : 0.7)

                for rect in rects {
                    let tRect = transformed(rect)
                    let path = Path(roundedRect: tRect, cornerRadius: 6 * scale)
                    ctx.fill(path, with: .color(baseColor.opacity(fillAlpha)))

                    if highlighted || selected {
                        ctx.stroke(path, with: .color(.white), lineWidth: 2)
                    }
                }
            }

            // Muscle labels
            drawLabels(ctx: ctx, scale: scale, xOff: xOff, yOff: yOff)
        }
        .background(Color(.systemBackground))
    }

    private func drawSilhouette(ctx: GraphicsContext, scale: CGFloat, xOff: CGFloat, yOff: CGFloat) {
        let bodyColor = Color(.systemGray5)

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat = 8) -> Path {
            let r = CGRect(x: x * scale + xOff, y: y * scale + yOff, width: w * scale, height: h * scale)
            return Path(roundedRect: r, cornerRadius: corner * scale)
        }

        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
            let origin = CGPoint(x: cx * scale + xOff - r * scale, y: cy * scale + yOff - r * scale)
            return Path(ellipseIn: CGRect(origin: origin, size: CGSize(width: r * 2 * scale, height: r * 2 * scale)))
        }

        // Head
        ctx.fill(circle(100, 20, 18), with: .color(bodyColor))
        // Neck
        ctx.fill(rect(88, 36, 24, 20, corner: 4), with: .color(bodyColor))
        // Torso
        ctx.fill(rect(57, 55, 86, 198, corner: 10), with: .color(bodyColor))
        // Left upper arm
        ctx.fill(rect(22, 55, 32, 118, corner: 8), with: .color(bodyColor))
        // Right upper arm
        ctx.fill(rect(146, 55, 32, 118, corner: 8), with: .color(bodyColor))
        // Left forearm
        ctx.fill(rect(18, 174, 28, 90, corner: 7), with: .color(bodyColor))
        // Right forearm
        ctx.fill(rect(154, 174, 28, 90, corner: 7), with: .color(bodyColor))
        // Left thigh
        ctx.fill(rect(58, 255, 40, 126, corner: 9), with: .color(bodyColor))
        // Right thigh
        ctx.fill(rect(102, 255, 40, 126, corner: 9), with: .color(bodyColor))
        // Left calf
        ctx.fill(rect(60, 384, 35, 54, corner: 8), with: .color(bodyColor))
        // Right calf
        ctx.fill(rect(105, 384, 35, 54, corner: 8), with: .color(bodyColor))
    }

    private func drawLabels(ctx: GraphicsContext, scale: CGFloat, xOff: CGFloat, yOff: CGFloat) {
        for muscle in MuscleGroup.allCases {
            let visible = showFront ? muscle.visibleInFront : muscle.visibleInBack
            guard visible else { continue }
            let rects = showFront ? muscle.frontRects : muscle.backRects
            guard let first = rects.first else { continue }

            let cx = (first.midX) * scale + xOff
            let cy = (first.midY) * scale + yOff
            let fontSize = max(7, min(10, 9 * scale))

            let text = Text(muscle.shortName)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(Color.white)
            ctx.draw(text, at: CGPoint(x: cx, y: cy))
        }
    }

    // MARK: - Tap gesture

    private func tapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let scale = min(size.width / 200, size.height / 440)
                let xOff = (size.width - 200 * scale) / 2
                let yOff = max(12, (size.height - 440 * scale) / 2)

                let tapX = (value.location.x - xOff) / scale
                let tapY = (value.location.y - yOff) / scale

                let tappedMuscle = hitTest(x: tapX, y: tapY)

                withAnimation {
                    if let m = tappedMuscle {
                        if selectionMode {
                            viewModel.toggleMuscle(m)
                        } else {
                            selectedMuscle = selectedMuscle == m ? nil : m
                        }
                    } else if !selectionMode {
                        selectedMuscle = nil
                    }
                }
            }
    }

    private func hitTest(x: CGFloat, y: CGFloat) -> MuscleGroup? {
        for muscle in MuscleGroup.allCases {
            let visible = showFront ? muscle.visibleInFront : muscle.visibleInBack
            guard visible else { continue }
            let rects = showFront ? muscle.frontRects : muscle.backRects
            for rect in rects where rect.contains(CGPoint(x: x, y: y)) {
                return muscle
            }
        }
        return nil
    }

    // MARK: - Selection banner

    private var selectionBanner: some View {
        HStack {
            Text("\(viewModel.selectedMuscles.count)部位選択中")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            if !viewModel.selectedMuscles.isEmpty {
                Button("プランを作成") { showPlanSheet = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    // MARK: - Muscle detail panel

    private func muscleDetailPanel(muscle: MuscleGroup) -> some View {
        let stats = viewModel.muscleStats[muscle]

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(muscle.rawValue)
                    .font(.headline)
                Spacer()
                deviationBadge(muscle: muscle)
            }

            HStack(spacing: 20) {
                statItem(title: "偏差値", value: String(format: "%.1f", stats?.deviation ?? 50))
                statItem(title: "ボリューム(30日)", value: formatVolume(stats?.totalVolume ?? 0))
                statItem(title: "最終トレ", value: lastWorkoutText(stats?.lastWorkoutDate))
            }

            HStack(spacing: 10) {
                NavigationLink(destination: ExerciseListView(muscle: muscle)) {
                    Label("種目を見る", systemImage: "dumbbell")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.selectedMuscles = [muscle]
                    showPlanSheet = true
                } label: {
                    Label("今日鍛える", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
    }

    private func deviationBadge(muscle: MuscleGroup) -> some View {
        let stats = viewModel.muscleStats[muscle]
        let dev = stats?.deviation ?? 50
        let label = stats?.deviationLabel ?? "データなし"
        let color = StatsCalculator.colorForDeviation(dev)

        return Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1ft", volume / 1000)
        }
        return String(format: "%.0fkg", volume)
    }

    private func lastWorkoutText(_ date: Date?) -> String {
        guard let date else { return "なし" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "今日" }
        if days == 1 { return "昨日" }
        return "\(days)日前"
    }

    // MARK: - Plan generation sheet

    private var planGenerationSheet: some View {
        NavigationStack {
            PlanGenerationOptionsView(
                selectedMuscles: Array(viewModel.selectedMuscles),
                onGenerate: { plan in
                    viewModel.savePlan(plan)
                    showPlanSheet = false
                    selectionMode = false
                    viewModel.clearSelection()
                }
            )
            .navigationTitle("プランを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { showPlanSheet = false }
                }
            }
        }
    }
}

// MARK: - Exercise list for muscle

struct ExerciseListView: View {
    let muscle: MuscleGroup
    @EnvironmentObject private var viewModel: WorkoutViewModel

    var exercises: [Exercise] {
        ExerciseDatabase.exercises(for: muscle, anytimeOnly: viewModel.anytimeFilterEnabled)
    }

    var body: some View {
        List(exercises) { ex in
            NavigationLink(destination: ExerciseDetailView(exercise: ex)) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ex.name).font(.body)
                    HStack {
                        Text(ex.equipment).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(ex.difficulty.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(difficultyColor(ex.difficulty).opacity(0.15))
                            .foregroundStyle(difficultyColor(ex.difficulty))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(muscle.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Toggle("エニタイムのみ", isOn: $viewModel.anytimeFilterEnabled)
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
        }
    }

    private func difficultyColor(_ d: Exercise.Difficulty) -> Color {
        switch d {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

// MARK: - Plan generation options

struct PlanGenerationOptionsView: View {
    let selectedMuscles: [MuscleGroup]
    let onGenerate: (WorkoutPlan) -> Void

    @EnvironmentObject private var planGenerator: PlanGeneratorViewModel
    @EnvironmentObject private var viewModel: WorkoutViewModel
    @State private var daysPerWeek = 3

    var body: some View {
        Form {
            Section("対象部位") {
                if selectedMuscles.isEmpty {
                    Text("自動（偏差値が低い部位を優先）").foregroundStyle(.secondary)
                } else {
                    ForEach(selectedMuscles) { muscle in
                        Label(muscle.rawValue, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("週のトレーニング日数") {
                Picker("日数", selection: $daysPerWeek) {
                    Text("週3日").tag(3)
                    Text("週4日").tag(4)
                    Text("週5日").tag(5)
                }
                .pickerStyle(.segmented)
            }

            Section("設備フィルター") {
                Toggle("エニタイムフィットネスの設備のみ", isOn: $viewModel.anytimeFilterEnabled)
            }

            Section {
                Button {
                    let plan = planGenerator.generatePlan(
                        stats: viewModel.muscleStats,
                        daysPerWeek: daysPerWeek,
                        focusOverride: selectedMuscles,
                        anytimeOnly: viewModel.anytimeFilterEnabled
                    )
                    onGenerate(plan)
                } label: {
                    HStack {
                        Spacer()
                        Label("プランを生成", systemImage: "wand.and.stars")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
