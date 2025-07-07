import SwiftUI
import SwiftData
import Foundation

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var task: Task

    @State private var newTaskName: String = ""

    @State private var isTimerRunning = false
    @State private var currentDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentEntry: TimeEntry? // 現在計測中のTimeEntry
    private var timerRunningKey: String { "timerRunning_\(task.id.uuidString)" }
    private var timerStartTimeKey: String { "timerStartTime_\(task.id.uuidString)" }
    private var currentEntryIDKey: String { "currentEntryID_\(task.id.uuidString)" }
    @Query private var allTimeEntries: [TimeEntry]
    private var timeEntries: [TimeEntry] {
        task.timeEntries?.sorted(by: { $0.startTime > $1.startTime }) ?? []
    }

    // ★修正: 記録停止後のメモ/満足度入力用State
    @State private var showingLogDetailsSheet = false // シート表示用
    @State private var inputMemo: String = ""
    @State private var selectedSentiment: Sentiment = .normal // 満足度をGood/Bad/Normalで保持

    // ★追加: 満足度選択用のEnum
    enum Sentiment {
        case good, normal, bad

        var score: Int {
            switch self {
            case .good: return 10
            case .normal: return 5
            case .bad: return 1
            }
        }

        var iconName: String {
            switch self {
            case .good: return "hand.thumbsup.fill"
            case .normal: return "minus.square.fill" // Normalのアイコンはシンプルに
            case .bad: return "hand.thumbsdown.fill"
            }
        }
    }

    var body: some View {
        Form {
            Section("Task Details") {
                TextField("Task Name", text: $newTaskName)
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
                        showingLogDetailsSheet = true // シートを表示
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

            // ★削除: 満足度入力セクションはシートに移動
            // Section("Satisfaction Score") { ... }

            Section("Past Records") {
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
                            if let score = entry.satisfactionScore {
                                HStack {
                                    Text("Satisfaction:") // Localizable.xcstringsにキーを追加
                                    Image(systemName: score == 10 ? Sentiment.good.iconName : (score == 1 ? Sentiment.bad.iconName : Sentiment.normal.iconName))
                                        .foregroundColor(score == 10 ? .green : (score == 1 ? .red : .gray))
                                    Text("\(score)/10") // スコアも表示
                                }
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
                    saveTaskName()
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
        // ★追加: 記録詳細入力シート
        .sheet(isPresented: $showingLogDetailsSheet) {
            NavigationView {
                Form {
                    Section("Log Details") { // Localizable.xcstringsにキーを追加
                        TextField("Memo", text: $inputMemo, axis: .vertical) // 複数行対応
                            .lineLimit(5) // 最大行数
                        
                        VStack(alignment: .leading) {
                            Text("Satisfaction") // Localizable.xcstringsにキーを追加
                            HStack {
                                Spacer()
                                Button {
                                    selectedSentiment = (selectedSentiment == .good) ? .normal : .good // トグル
                                } label: {
                                    Image(systemName: Sentiment.good.iconName)
                                        .font(.largeTitle)
                                        .foregroundColor(selectedSentiment == .good ? .green : .gray)
                                }
                                Spacer()
                                Button {
                                    selectedSentiment = (selectedSentiment == .bad) ? .normal : .bad // トグル
                                } label: {
                                    Image(systemName: Sentiment.bad.iconName)
                                        .font(.largeTitle)
                                        .foregroundColor(selectedSentiment == .bad ? .red : .gray)
                                }
                                Spacer()
                            }
                            .buttonStyle(.plain) // ボタンのスタイルをリセット
                        }
                    }
                }
                .navigationTitle("Log Details") // Localizable.xcstringsにキーを追加
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { // Localizable.xcstringsにキーを追加
                            // キャンセル時にStateをリセット
                            inputMemo = ""
                            selectedSentiment = .normal
                            showingLogDetailsSheet = false
                            currentEntry = nil // currentEntry をクリア
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { // Localizable.xcstringsにキーを追加
                            if let entry = currentEntry {
                                entry.memo = inputMemo
                                entry.satisfactionScore = selectedSentiment.score
                            }
                            // 保存後にStateをリセット
                            inputMemo = ""
                            selectedSentiment = .normal
                            showingLogDetailsSheet = false
                            currentEntry = nil // currentEntry をクリア
                        }
                    }
                }
            }
        }
    }

    private func setupTaskDetailViewOnAppear() {
        setupTimerOnAppear()
        newTaskName = task.name
    }

    private func saveTaskName() {
        task.name = newTaskName
    }

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
        currentEntry = newEntry // 新しいTimeEntryをcurrentEntryに保持

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
            // currentEntry はシートでの保存後に nil にする
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

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

        let sampleProject = Project(name: "開発", colorHex: "#007AFF")
        let sampleTask = Task(name: "UI実装", orderIndex: 0, project: sampleProject)
        // ★修正: TimeEntryの初期化にmemoとsatisfactionScoreを追加
        let sampleTimeEntry1 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3000), duration: 600, memo: "ボタン配置", satisfactionScore: 8)
        let sampleTimeEntry2 = TimeEntry(id: UUID(), startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-6000), duration: 1200, memo: "データモデル設計", satisfactionScore: 7)
        sampleTask.timeEntries = [sampleTimeEntry1, sampleTimeEntry2]

        container.mainContext.insert(sampleProject)
        container.mainContext.insert(sampleTask)

        return TaskDetailView(task: sampleTask)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }
}
