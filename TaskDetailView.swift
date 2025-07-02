//
//  TaskDetailView.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: Task // 選択されたタスクを受け取る

    @State private var isTimerRunning = false // タイマーが実行中かどうかのフラグ
    @State private var currentDuration: TimeInterval = 0 // 現在の計測時間
    @State private var timer: Timer? // タイマーインスタンス
    @State private var currentEntry: TimeEntry? // 現在計測中のTimeEntry

    // タスクに紐づく時間記録を取得
    private var timeEntries: [TimeEntry] {
        task.timeEntries?.sorted(by: { $0.startTime > $1.startTime }) ?? [] // 最新の記録が上に来るようにソート
    }

    var body: some View {
        VStack {
            // 現在の計測時間を表示
            Text(formattedCurrentDuration)
                .font(.largeTitle)
                .padding()

            HStack {
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "停止" : "開始")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isTimerRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.vertical)

            // 過去の時間記録の一覧
            List {
                Section("過去の記録") {
                    if timeEntries.isEmpty {
                        Text("まだ時間記録がありません。")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(timeEntries) { entry in
                            VStack(alignment: .leading) {
                                Text("開始: \(entry.startTime, formatter: itemFormatter)")
                                if let endTime = entry.endTime {
                                    Text("終了: \(endTime, formatter: itemFormatter)")
                                }
                                Text("時間: \(formattedDuration(entry.duration))")
                                if !entry.memo.isEmpty {
                                    Text("メモ: \(entry.memo)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteTimeEntries)
                    }
                }
            }
        }
        .navigationTitle(task.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupTimer) // ビューが表示されたときにタイマーの状態をセットアップ
        .onDisappear(perform: cleanupTimer) // ビューが非表示になったときにタイマーをクリーンアップ
    }

    // 時間計測開始
    // TaskDetailView.swift 内の startTimer() メソッド

    private func startTimer() {
        isTimerRunning = true
        let newEntry = TimeEntry(startTime: Date(), task: task)
        
        // modelContextに挿入
        modelContext.insert(newEntry)
        
        // ここが肝心: taskのtimeEntries配列に新しいエントリを追加
        // `task.timeEntries` がOptionalなので、nilの場合は初期化し、その後に追加します。
        if task.timeEntries == nil {
            task.timeEntries = []
        }
        task.timeEntries?.append(newEntry) // これでリレーションシップが確立され、SwiftDataが更新を検知しやすくなります

        currentEntry = newEntry

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let entry = currentEntry {
                currentDuration = Date().timeIntervalSince(entry.startTime)
            }
        }
        
        // 必要に応じて、変更を即座に保存させるための強制的なフラッシュを試みる
        // 通常は不要ですが、動作が不安定な場合は試す価値あり
        // try? modelContext.save()
    }
    
    // 時間計測停止
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate() // タイマーを停止
        timer = nil

        if let entry = currentEntry {
            entry.endTime = Date() // 終了時刻を記録
            entry.duration = currentDuration // 最終的な時間を記録
            currentEntry = nil // 現在の計測エントリをリセット
            currentDuration = 0 // 表示時間をリセット
        }
        // modelContext.save() は不要 (SwiftDataが自動で変更を検知し保存)
    }

    // ビュー表示時のタイマーセットアップ
    private func setupTimer() {
        // アプリが中断された場合などに備え、未終了のTimeEntryがあれば再開
        if let ongoingEntry = task.timeEntries?.first(where: { $0.endTime == nil }) {
            currentEntry = ongoingEntry
            isTimerRunning = true
            currentDuration = Date().timeIntervalSince(ongoingEntry.startTime)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentDuration = Date().timeIntervalSince(ongoingEntry.startTime)
            }
        }
    }

    // ビュー非表示時のタイマークリーンアップ
    private func cleanupTimer() {
        // ビューを離れる際にタイマーが実行中であれば停止
        if isTimerRunning {
            // アプリがバックグラウンドに回った場合などを考慮し、ここでは停止しない
            // アプリが完全に終了した場合や、別のタスクに切り替わった場合などの考慮は別途必要
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    // 時間記録削除関数
    private func deleteTimeEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(timeEntries[index])
            }
        }
    }

    // 時間をHH:MM:SS形式でフォーマット
    private var formattedCurrentDuration: String {
        formattedDuration(currentDuration)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// 日付フォーマッター
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

// Xcodeのプレビュー用
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    let sampleProject = Project(name: "開発", colorHex: "#007AFF")
    let sampleTask = Task(name: "UI実装", project: sampleProject)
    let sampleTimeEntry1 = TimeEntry(startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3000), duration: 600, memo: "ボタン配置")
    let sampleTimeEntry2 = TimeEntry(startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-6000), duration: 1200, memo: "データモデル設計")
    sampleTask.timeEntries = [sampleTimeEntry1, sampleTimeEntry2]

    return TaskDetailView(task: sampleTask)
        .modelContainer(container)
}
