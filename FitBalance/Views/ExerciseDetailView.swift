import SwiftUI
import SafariServices

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showVideo = false

    var body: some View {
        List {
            // Basic info
            Section {
                LabeledContent("器具", value: exercise.equipment)
                LabeledContent("難易度", value: exercise.difficulty.rawValue)
                LabeledContent("エニタイム対応", value: exercise.isAnytimeCompatible ? "対応" : "要確認")
            }

            // Target muscles
            Section("メインターゲット") {
                ForEach(exercise.primaryMuscles) { muscle in
                    HStack {
                        Circle()
                            .fill(StatsCalculator.colorForDeviation(50))
                            .frame(width: 8, height: 8)
                        Text(muscle.rawValue)
                    }
                }
            }

            if !exercise.secondaryMuscles.isEmpty {
                Section("サブターゲット") {
                    ForEach(exercise.secondaryMuscles) { muscle in
                        HStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.6))
                                .frame(width: 8, height: 8)
                            Text(muscle.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Video link
            Section("解説動画") {
                Button {
                    showVideo = true
                } label: {
                    Label("YouTubeで「\(exercise.name) やり方」を検索", systemImage: "play.rectangle.fill")
                        .foregroundStyle(.red)
                }
            }

            // Tips
            Section("トレーニングのポイント") {
                ForEach(tips(for: exercise), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                            .padding(.top, 1)
                        Text(tip)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showVideo) {
            if let url = exercise.videoSearchURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    private func tips(for exercise: Exercise) -> [String] {
        var tips: [String] = []
        let primary = exercise.primaryMuscles.first

        switch primary {
        case .chest:
            tips = ["胸を張り、肩甲骨を寄せて始める",
                    "バーの軌道は胸の中央を意識",
                    "肘は45〜75度に保つ"]
        case .back:
            tips = ["背中を丸めず、胸を前に張る",
                    "肘を後ろに引くイメージで収縮",
                    "ストレッチポジションで完全に伸ばす"]
        case .shoulders:
            tips = ["前傾しすぎず、体幹をブレさせない",
                    "肘の高さは肩と同じかやや下",
                    "反動を使わずゆっくり行う"]
        case .biceps:
            tips = ["肘の位置を固定して動かさない",
                    "前腕を外側に回しながら持ち上げる",
                    "コントロールしながらゆっくり降ろす"]
        case .triceps:
            tips = ["肘の位置を動かさないよう固定する",
                    "完全に伸展してから次の動作へ",
                    "手首は真っ直ぐ保つ"]
        case .core:
            tips = ["腰を反らさず、骨盤を後傾気味に",
                    "呼吸を止めず、収縮時に吐く",
                    "反動をつけず丁寧にコントロール"]
        case .quads:
            tips = ["つま先と膝の向きをそろえる",
                    "膝がつま先より前に出ないよう注意",
                    "深さはハムストリングが床と平行になるまで"]
        case .hamstrings, .glutes:
            tips = ["骨盤を後傾させず、前傾を維持",
                    "臀部を意識してスクイーズする",
                    "体幹を安定させて行う"]
        case .calves:
            tips = ["足首を完全に伸ばすところまで上げる",
                    "下げる動作もゆっくり行う",
                    "両足でバランスよく荷重する"]
        case .forearms, .none:
            tips = ["フォームを崩さない重量を選ぶ",
                    "呼吸を整えながらコントロールする",
                    "十分なウォームアップを行う"]
        }
        return tips
    }
}

// MARK: - Safari wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
