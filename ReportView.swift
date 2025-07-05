import SwiftUI
import SwiftData
import Charts // ★追加: Chartsフレームワークをインポート

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext

    // TimeEntryを全て取得（後で期間でフィルタリング）
    @Query private var timeEntries: [TimeEntry]
    @Query private var projects: [Project] // プロジェクト情報も取得

    @State private var selectedPeriod: ReportPeriod = .week // ★追加: 期間選択の状態
    @State private var selectedDate: Date = Date() // ★追加: 選択された日付（週や月の基準日）

    enum ReportPeriod: String, CaseIterable, Identifiable {
        case week = "Week" // Localizable.xcstrings にキーを追加
        case month = "Month" // Localizable.xcstrings にキーを追加
        var id: String { self.rawValue }
    }

    // 選択された期間と日付に基づいてフィルタリングされた時間エントリ
    private var filteredTimeEntries: [TimeEntry] {
        let calendar = Calendar.current
        return timeEntries.filter { entry in
            guard let endTime = entry.endTime else { return false } // 終了していないエントリは含めない

            switch selectedPeriod {
            case .week:
                return calendar.isDate(endTime, equalTo: selectedDate, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(endTime, equalTo: selectedDate, toGranularity: .month)
            }
        }
    }

    // プロジェクトごとの時間集計
    private var projectTimeData: [ProjectTime] {
        var projectDurations: [UUID: TimeInterval] = [:]
        for entry in filteredTimeEntries {
            if let projectId = entry.task?.project?.id {
                projectDurations[projectId, default: 0] += entry.duration
            }
        }

        let totalDuration = projectDurations.values.reduce(0, +)

        return projectDurations.compactMap { (projectId, duration) in
            if let project = projects.first(where: { $0.id == projectId }) {
                let percentage = totalDuration > 0 ? (duration / totalDuration) * 100 : 0
                return ProjectTime(project: project, duration: duration, percentage: percentage)
            }
            return nil
        }.sorted { $0.duration > $1.duration } // 時間の長い順にソート
    }

    // グラフ表示用のデータ構造
    struct ProjectTime: Identifiable {
        let id = UUID()
        let project: Project
        let duration: TimeInterval
        let percentage: Double
    }

    var body: some View {
        NavigationStack {
            Form {
                // 期間選択ピッカー
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedPeriod) {
                    // 期間が変更されたら日付を今日にリセット
                    selectedDate = Date()
                }
                // 日付選択（週/月移動）
                HStack {
                    Button(action: {
                        changeDate(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(dateRangeString())
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        changeDate(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }

                Section("Time Allocation") { // Localizable.xcstrings にキーを追加
                    if projectTimeData.isEmpty {
                        ContentUnavailableView("NoDataForPeriod", systemImage: "chart.pie") // Localizable.xcstrings にキーを追加
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        // 円グラフの表示
                        Chart {
                            ForEach(projectTimeData) { data in
                                SectorMark(
                                    angle: .value("Duration", data.duration),
                                    innerRadius: 60, // ドーナツグラフにする
                                    outerRadius: 100,
                                    angularInset: 1.0
                                )
                                .foregroundStyle(by: .value("Project", data.project.name))
                                .annotation(position: .overlay) {
                                    Text(String(format: "%.1f%%", data.percentage))
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 250)
                        .chartForegroundStyleScale(
                            domain: projectTimeData.map { $0.project.name },
                            range: projectTimeData.map { Color(hex: $0.project.colorHex) ?? .gray }
                        )
                        .padding(.vertical)

                        // プロジェクトごとの時間と割合のリスト
                        ForEach(projectTimeData) { data in
                            HStack {
                                Circle()
                                    .fill(Color(hex: data.project.colorHex) ?? .gray)
                                    .frame(width: 10, height: 10)
                                Text(data.project.name)
                                Spacer()
                                Text(formatDuration(data.duration))
                                Text(String(format: "(%.1f%%)", data.percentage))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                // ここに今後のレポート機能を追加
                Section("Future Reports") { // Localizable.xcstrings にキーを追加
                    Text("More detailed reports and insights will be available here.") // Localizable.xcstrings にキーを追加
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("ReportsTabTitle") // Localizable.xcstrings にキーを追加
        }
    }

    // MARK: - Helper Functions

    private func changeDate(by amount: Int) {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week:
            if let newDate = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate) {
                selectedDate = newDate
            }
        case .month:
            if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }

    private func dateRangeString() -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()

        switch selectedPeriod {
        case .week:
            // 週の開始日と終了日を計算
            guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)),
                  let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
                return "Invalid Week"
            }
            dateFormatter.dateFormat = "yyyy/MM/dd"
            return "\(dateFormatter.string(from: weekStartDate)) - \(dateFormatter.string(from: weekEndDate))"
        case .month:
            // 月の表示
            dateFormatter.dateFormat = "yyyy年MM月"
            return dateFormatter.string(from: selectedDate)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d時間%02d分", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分%02d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    // Helper function to create and populate the ModelContainer
    @MainActor
    func createPreviewContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

        // Sample projects
        let sampleProject1 = Project(name: "自己成長", colorHex: "#007AFF", lifeBalance: 25)
        let sampleProject2 = Project(name: "仕事", colorHex: "#DC3545", lifeBalance: 50)
        let sampleProject3 = Project(name: "趣味", colorHex: "#6F42C1", lifeBalance: 25)

        container.mainContext.insert(sampleProject1)
        container.mainContext.insert(sampleProject2)
        container.mainContext.insert(sampleProject3)

        // Sample tasks
        let task1_1 = Task(name: "読書", project: sampleProject1)
        let task2_1 = Task(name: "開発", project: sampleProject2)
        let task3_1 = Task(name: "ゲーム", project: sampleProject3)

        container.mainContext.insert(task1_1)
        container.mainContext.insert(task2_1)
        container.mainContext.insert(task3_1)

        // Current week’s data
        let now = Date()
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        let timeEntry1 = TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 9), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 10), duration: 3600, task: task1_1) // 月曜日 1時間
        let timeEntry2 = TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 10), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 12), duration: 7200, task: task2_1) // 火曜日 2時間
        let timeEntry3 = TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 2 + 3600 * 20), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 2 + 3600 * 21), duration: 3600, task: task3_1) // 水曜日 1時間
        let timeEntry4 = TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 3 + 3600 * 14), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 3 + 3600 * 15 + 1800), duration: 5400, task: task1_1) // 木曜日 1.5時間
        let timeEntry5 = TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 4 + 3600 * 9), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 4 + 3600 * 13), duration: 14400, task: task2_1) // 金曜日 4時間

        // Last month’s data
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let startOfLastMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth))!

        let timeEntry6 = TimeEntry(startTime: startOfLastMonth.addingTimeInterval(3600 * 24 * 5 + 3600 * 9), endTime: startOfLastMonth.addingTimeInterval(3600 * 24 * 5 + 3600 * 10), duration: 3600, task: task1_1) // 先月 1時間
        let timeEntry7 = TimeEntry(startTime: startOfLastMonth.addingTimeInterval(3600 * 24 * 10 + 3600 * 10), endTime: startOfLastMonth.addingTimeInterval(3600 * 24 * 10 + 3600 * 12), duration: 7200, task: task2_1) // 先月 2時間

        container.mainContext.insert(timeEntry1)
        container.mainContext.insert(timeEntry2)
        container.mainContext.insert(timeEntry3)
        container.mainContext.insert(timeEntry4)
        container.mainContext.insert(timeEntry5)
        container.mainContext.insert(timeEntry6)
        container.mainContext.insert(timeEntry7)

        return container
    }

    do {
        let container = try createPreviewContainer()
        return ReportView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }
}
