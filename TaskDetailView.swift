import SwiftUI
import SwiftData
import Foundation

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var task: Task

    @State private var newTaskName: String = ""
    @State private var newTaskMemo: String = ""
    // ★削除: @State private var newCategory: String = ""
    @State private var newSatisfactionScore: Int = 5

    // ★削除: let categories = [...]

    @State private var isTimerRunning = false
    @State private var currentDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentEntry: TimeEntry?
    private var timerRunningKey: String { "timerRunning_\(task.id.uuidString)" }
    private var timerStartTimeKey: String { "timerStartTime_\(task.id.uuidString)" }
    private var currentEntryIDKey: String { "currentEntryID_\(task.id.uuidString)" }
    @Query private var allTimeEntries: [TimeEntry]
    private var timeEntries: [TimeEntry] {
        task.timeEntries?.sorted(by: { $0.startTime > $1.startTime }) ?? []
    }

    var body: some View {
        Form {
            // タスク詳細編集セクション
            Section("TaskDetails") {
                TextField("TaskName", text: $newTaskName)
                
                // ★削除: カテゴリ選択ピッカー
                // Picker("Category", selection: $newCategory) {
                //     ForEach(categories, id: \.self) { category in
                //         Text(category).tag(category)
                //     }
                // }
                
                TextEditor(text: $newTaskMemo)
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if newTaskMemo.isEmpty {
                                Text("Memo (Optional)")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                        }, alignment: .topLeading
                    )
            }
            
            Section {
                Text(formattedCurrentDuration)
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)

                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "Stop" : "Start")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isTimerRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            Section("Satisfaction Score") {
                Stepper(value: $newSatisfactionScore, in: 1...10) {
                    Text("Score: \(newSatisfactionScore)")
                }
            }

            Section("PastRecords") {
                if timeEntries.isEmpty {
                    Text("NoTimeRecordedYet")
                        .foregroundColor(.gray)
                } else {
                    ForEach(timeEntries) { entry in
                        VStack(alignment: .leading) {
                            Text("StartAtFormat \(entry.startTime, formatter: itemFormatter)")
                            if let endTime = entry.endTime {
                                Text("EndAtFormat \(endTime, formatter: itemFormatter)")
                            }
                            Text("TimeFormat \(formattedDuration(entry.duration))")
                            if !entry.memo.isEmpty {
                                Text("NoteFormat \(entry.memo)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTimeEntries)
                }
            }
        }
        .navigationTitle(task.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveTaskDetails()
                    dismiss()
                }
                .disabled(newTaskName.isEmpty)
            }
        }
        .onAppear(perform: setupTaskDetailViewOnAppear)
        .onDisappear(perform: cleanupTimerOnDisappear)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            setupTimerOnAppear()
        }
    }

    private func setupTaskDetailViewOnAppear() {
        setupTimerOnAppear()
        newTaskName = task.name
        newTaskMemo = task.memo
        // ★削除: newCategory = task.category
        newSatisfactionScore = task.satisfactionScore ?? 5
    }

    private func saveTaskDetails() {
        task.name = newTaskName
        task.memo = newTaskMemo
        // ★削除: task.category = newCategory
        task.satisfactionScore = newSatisfactionScore
    }

    // ... タイマー関連の関数は変更なし ...
    private func setupTimerOnAppear() {
        let storedIsRunning = UserDefaults.standard.bool(forKey: timerRunningKey)
        if storedIsRunning, let storedStartTime = UserDefaults.standard.object(forKey: timerStartTimeKey) as? Date,
           let storedEntryIDString = UserDefaults.standard.string(forKey: currentEntryIDKey),
           let storedEntryUUID = UUID(uuidString: storedEntryIDString),
           let ongoingEntry = allTimeEntries.first(where: { $0.id == storedEntryUUID }) {
            
            guard ongoingEntry.task?.id == task.id else { return }

            currentEntry = ongoingEntry
            isTimerRunning = true
            currentDuration = Date().timeIntervalSince(storedStartTime)

            if timer == nil {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if let entry = currentEntry {
                        currentDuration = Date().timeIntervalSince(entry.startTime)
                    }
                }
            }
        } else {
            isTimerRunning = false
            currentDuration = 0
            timer?.invalidate()
            timer = nil
            UserDefaults.standard.removeObject(forKey: timerRunningKey)
            UserDefaults.standard.removeObject(forKey: timerStartTimeKey)
            UserDefaults.standard.removeObject(forKey: currentEntryIDKey)
        }
    }

    private func cleanupTimerOnDisappear() {}

    private func startTimer() {
        isTimerRunning = true
        let newEntry = TimeEntry(startTime: Date(), task: task)

        modelContext.insert(newEntry)
        if task.timeEntries == nil {
            task.timeEntries = []
        }
        task.timeEntries?.append(newEntry)
        currentEntry = newEntry

        UserDefaults.standard.set(true, forKey: timerRunningKey)
        UserDefaults.standard.set(newEntry.startTime, forKey: timerStartTimeKey)
        UserDefaults.standard.set(newEntry.id.uuidString, forKey: currentEntryIDKey)

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

// Xcodeのプレビュー用（テストデータ）
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

        // ★修正: ProjectにhappinessWeightを追加
        let sampleProject = Project(name: "開発", colorHex: "#007AFF", happinessWeight: 30)
        // ★修正: Taskにcategory引数がなくなった
        let sampleTask = Task(name: "UI実装", memo: "新規機能追加", satisfactionScore: 8, project: sampleProject)
        let sampleTimeEntry1 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3000), duration: 600, memo: "ボタン配置")
        let sampleTimeEntry2 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-6000), duration: 1200, memo: "データモデル設計")
        sampleTask.timeEntries = [sampleTimeEntry1, sampleTimeEntry2]

        container.mainContext.insert(sampleProject)
        container.mainContext.insert(sampleTask)
        container.mainContext.insert(sampleTimeEntry1)
        container.mainContext.insert(sampleTimeEntry2)

        return TaskDetailView(task: sampleTask)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }
}
