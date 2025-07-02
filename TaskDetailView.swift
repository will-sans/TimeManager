import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: Task // 選択されたタスクを受け取る

    @State private var isTimerRunning = false // タイマーが実行中かどうかのフラグ
    @State private var currentDuration: TimeInterval = 0 // 現在の計測時間
    @State private var timer: Timer? // タイマーインスタンス
    @State private var currentEntry: TimeEntry? // 現在計測中のTimeEntry

    // UserDefaultsにタイマー状態を保存するためのキー
    // 各タスクにユニークなIDを使用
    private var timerRunningKey: String { "timerRunning_\(task.id.uuidString)" } // ★修正: .id.uuidString
    private var timerStartTimeKey: String { "timerStartTime_\(task.id.uuidString)" } // ★修正: .id.uuidString
    private var currentEntryIDKey: String { "currentEntryID_\(task.id.uuidString)" } // ★修正: .id.uuidString
    
    // TimeEntryをIDで取得するためのヘルパー
    @Query private var allTimeEntries: [TimeEntry]

    // タスクに紐づく時間記録を取得
    private var timeEntries: [TimeEntry] {
        task.timeEntries?.sorted(by: { $0.startTime > $1.startTime }) ?? [] // 最新の記録が上に来るようにソート
    }

    var body: some View {
        VStack {
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
        .onAppear(perform: setupTimerOnAppear) // ビューが表示されたときにタイマーの状態をセットアップ
        .onDisappear(perform: cleanupTimerOnDisappear) // ビューが非表示になったときにタイマーをクリーンアップ

        // アプリがアクティブになった際の通知を購読
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // アプリがフォアグラウンドに戻った時にタイマーの状態を再確認
            setupTimerOnAppear()
        }
    }

    // ビュー表示時のタイマーセットアップ
    private func setupTimerOnAppear() {
        // UserDefaultsからタイマーの状態を復元
        let storedIsRunning = UserDefaults.standard.bool(forKey: timerRunningKey)
        if storedIsRunning, let storedStartTime = UserDefaults.standard.object(forKey: timerStartTimeKey) as? Date,
           let storedEntryIDString = UserDefaults.standard.string(forKey: currentEntryIDKey),
           let storedEntryUUID = UUID(uuidString: storedEntryIDString), // ★修正: UUIDを直接扱う
           // allTimeEntriesからID（UUID）でTimeEntryを検索
           let ongoingEntry = allTimeEntries.first(where: { $0.id == storedEntryUUID }) { // ★修正: .id ==
            
            // 復元したTimeEntryが現在のタスクに紐づくか確認
            guard ongoingEntry.task?.id == task.id else { return } // ★修正: .id ==

            currentEntry = ongoingEntry
            isTimerRunning = true
            currentDuration = Date().timeIntervalSince(storedStartTime) // 保存された開始時刻から経過時間を計算

            // タイマーがまだ動いていなければ再開
            if timer == nil {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if let entry = currentEntry {
                        currentDuration = Date().timeIntervalSince(entry.startTime)
                    }
                }
            }
        } else {
            // 保存された状態がない、または無効な場合はタイマーを停止状態にリセット
            isTimerRunning = false
            currentDuration = 0
            timer?.invalidate()
            timer = nil
            UserDefaults.standard.removeObject(forKey: timerRunningKey)
            UserDefaults.standard.removeObject(forKey: timerStartTimeKey)
            UserDefaults.standard.removeObject(forKey: currentEntryIDKey)
        }
    }

    // ビュー非表示時のタイマークリーンアップ（ここではタイマー自体は停止しない）
    private func cleanupTimerOnDisappear() {
        // ビューを離れるだけなのでタイマーはそのままにしておく
        // タイマーが動作している場合、アプリがバックグラウンドに行っても継続したいので
        // ここで invalidate はしない
    }

    private func startTimer() {
        isTimerRunning = true
        let newEntry = TimeEntry(startTime: Date(), task: task)

        modelContext.insert(newEntry)
        if task.timeEntries == nil {
            task.timeEntries = []
        }
        task.timeEntries?.append(newEntry)
        currentEntry = newEntry

        // タイマーの状態と開始時刻、現在のエントリのIDをUserDefaultsに保存
        UserDefaults.standard.set(true, forKey: timerRunningKey)
        UserDefaults.standard.set(newEntry.startTime, forKey: timerStartTimeKey)
        UserDefaults.standard.set(newEntry.id.uuidString, forKey: currentEntryIDKey) // ★修正: .id.uuidString

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let entry = currentEntry {
                currentDuration = Date().timeIntervalSince(entry.startTime)
            }
        }
    }

    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil

        if let entry = currentEntry {
            entry.endTime = Date()
            entry.duration = currentDuration
            currentEntry = nil
            currentDuration = 0
        }

        // UserDefaultsからタイマーの状態をクリア
        UserDefaults.standard.removeObject(forKey: timerRunningKey)
        UserDefaults.standard.removeObject(forKey: timerStartTimeKey)
        UserDefaults.standard.removeObject(forKey: currentEntryIDKey)
    }

    private func deleteTimeEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(timeEntries[index])
            }
        }
    }

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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    let sampleProject = Project(name: "開発", colorHex: "#007AFF")
    let sampleTask = Task(name: "UI実装", project: sampleProject)
    let sampleTimeEntry1 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3000), duration: 600, memo: "ボタン配置")
    let sampleTimeEntry2 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-6000), duration: 1200, memo: "データモデル設計")
    sampleTask.timeEntries = [sampleTimeEntry1, sampleTimeEntry2]

    return TaskDetailView(task: sampleTask)
        .modelContainer(container)
}
