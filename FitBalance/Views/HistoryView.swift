import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("トレーニング履歴")
        }
    }

    // MARK: - Session list

    private var sessionList: some View {
        List {
            ForEach(groupedSessions, id: \.key) { (monthKey, monthSessions) in
                Section(monthKey) {
                    ForEach(monthSessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            sessionRow(session)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            modelContext.delete(monthSessions[i])
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0fkg Vol.", session.totalVolume))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let muscleNames = session.muscleNames
            if !muscleNames.isEmpty {
                Text(muscleNames.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Label("\(session.exerciseLogs.count)種目", systemImage: "dumbbell")
                Label("\(session.exerciseLogs.reduce(0) { $0 + $1.sets.count })セット",
                      systemImage: "repeat")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Grouping

    private var groupedSessions: [(key: String, value: [WorkoutSession])] {
        var grouped: [String: [WorkoutSession]] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"

        for session in sessions {
            let key = formatter.string(from: session.date)
            grouped[key, default: []].append(session)
        }

        return grouped
            .map { (key: $0.key, value: $0.value) }
            .sorted { lhs, rhs in
                let fmt = DateFormatter()
                fmt.locale = Locale(identifier: "ja_JP")
                fmt.dateFormat = "yyyy年M月"
                let d1 = fmt.date(from: lhs.key) ?? Date.distantPast
                let d2 = fmt.date(from: rhs.key) ?? Date.distantPast
                return d1 > d2
            }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("履歴がありません")
                .font(.title2)
                .fontWeight(.semibold)
            Text("トレーニングを記録すると\nここに表示されます")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Session detail

struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section("サマリー") {
                LabeledContent("日時", value: session.date.formatted(date: .long, time: .omitted))
                LabeledContent("総ボリューム", value: String(format: "%.0f kg", session.totalVolume))
                LabeledContent("種目数", value: "\(session.exerciseLogs.count)")
                LabeledContent("総セット数",
                               value: "\(session.exerciseLogs.reduce(0) { $0 + $1.sets.count })")
            }

            ForEach(session.exerciseLogs) { log in
                Section(log.exerciseName) {
                    ForEach(Array(log.sets.enumerated()), id: \.offset) { idx, set in
                        HStack {
                            Text("セット \(idx + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.weight, specifier: "%.1f") kg × \(set.reps) 回")
                                .fontWeight(.medium)
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .imageScale(.small)
                            }
                        }
                    }
                    HStack {
                        Text("合計ボリューム")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f kg", log.totalVolume))
                            .fontWeight(.semibold)
                    }
                }
            }

            if !session.notes.isEmpty {
                Section("メモ") {
                    Text(session.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}
