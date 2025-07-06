import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var timeEntries: [TimeEntry]
    @Query private var projects: [Project]

    @AppStorage("startOfWeek") private var startOfWeek: Int = 1 // 1=Sunday, 2=Monday
    @State private var selectedPeriod: ReportPeriod = .week
    @State private var selectedDate: Date = Date()
    @State private var isNavigating: Bool = false // Prevent double taps

    enum ReportPeriod: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        var id: String { self.rawValue }
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = startOfWeek
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")! // Use JST
        return calendar
    }

    private var filteredTimeEntries: [TimeEntry] {
        let filtered = timeEntries.filter { entry in
            guard let endTime = entry.endTime else {
                print("Skipping entry with nil endTime: \(entry.id)")
                return false
            }

            let isMatch: Bool
            switch selectedPeriod {
            case .day:
                isMatch = calendar.isDate(endTime, inSameDayAs: selectedDate)
            case .week:
                isMatch = calendar.isDate(endTime, equalTo: selectedDate, toGranularity: .weekOfYear)
            case .month:
                isMatch = calendar.isDate(endTime, equalTo: selectedDate, toGranularity: .month)
            }
            print("Filtering entry: id=\(entry.id), endTime=\(endTime), selectedDate=\(selectedDate), period=\(selectedPeriod.rawValue), match=\(isMatch)")
            return isMatch
        }
        print("Filtered \(filtered.count) entries for period \(selectedPeriod.rawValue) on \(selectedDate)")
        return filtered
    }

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
        }.sorted { $0.duration > $1.duration }
    }

    struct ProjectTime: Identifiable {
        let id = UUID()
        let project: Project
        let duration: TimeInterval
        let percentage: Double
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedPeriod) {
                    selectedDate = Date()
                    print("Period changed to \(selectedPeriod.rawValue), reset selectedDate to \(selectedDate)")
                }

                // 修正後の日付ナビゲーション部分
                HStack {
                    Button(action: {
                        print("＜ボタン押下")
                        changeDate(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    .disabled(isNavigating)

                    Spacer(minLength: 20)

                    Text(dateRangeString())
                        .font(.headline)

                    Spacer(minLength: 20)

                    Button(action: {
                        print("＞ボタン押下")
                        changeDate(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    .disabled(isNavigating)
                }
                .padding(.vertical, 5)

                Section("Time Allocation") {
                    if projectTimeData.isEmpty {
                        ContentUnavailableView("NoDataForPeriod", systemImage: "chart.pie")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Chart {
                            ForEach(projectTimeData) { data in
                                SectorMark(
                                    angle: .value("Duration", data.duration),
                                    innerRadius: .ratio(0.6),
                                    outerRadius: .ratio(1.0),
                                    angularInset: 1.0
                                )
                                .foregroundStyle(by: .value("Project", data.project.name))
                                .annotation(position: .overlay) {
                                    if data.percentage >= 5 {
                                        Text(String(format: "%.1f%%", min(data.percentage, 100.0)))
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartForegroundStyleScale(
                            domain: projectTimeData.map { $0.project.name },
                            range: projectTimeData.map { Color(hex: $0.project.colorHex) ?? .gray }
                        )
                        .padding(.vertical)

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

                Section("Future Reports") {
                    Text("More detailed reports and insights will be available here.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("ReportsTabTitle")
        }
    }

    private func changeDate(by amount: Int) {
        guard !isNavigating else { return }
        isNavigating = true

        // 連打防止のため遅延でフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isNavigating = false
        }

        let newDate: Date?
        switch selectedPeriod {
        case .day:
            newDate = calendar.date(byAdding: .day, value: amount, to: selectedDate)
        case .week:
            newDate = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate)
        case .month:
            newDate = calendar.date(byAdding: .month, value: amount, to: selectedDate)
        }

        if let newDate {
            selectedDate = newDate
            print("Changed date by \(amount) for \(selectedPeriod.rawValue): new selectedDate=\(selectedDate)")
        }
    }

    private func dateRangeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo") // Use JST
        
        switch selectedPeriod {
        case .day:
            dateFormatter.dateFormat = "yyyy/MM/dd"
            return dateFormatter.string(from: selectedDate)
        case .week:
            guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)),
                  let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
                return "Invalid Week"
            }
            dateFormatter.dateFormat = "yyyy/MM/dd"
            return "\(dateFormatter.string(from: weekStartDate)) - \(dateFormatter.string(from: weekEndDate))"
        case .month:
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

        // Use JST timezone for consistency
        var previewCalendar = Calendar.current
        previewCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        previewCalendar.firstWeekday = 1 // Default to Sunday for preview
        let now = Date()
        let startOfDay = previewCalendar.startOfDay(for: now)

        // Previous day's data
        let previousDay = previewCalendar.date(byAdding: .day, value: -1, to: startOfDay)!

        // Next day's data
        let nextDay = previewCalendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Current week's data
        let startOfWeek = previewCalendar.date(from: previewCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        // Previous week's data
        let previousWeek = previewCalendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek)!

        // Next week's data
        let nextWeek = previewCalendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!

        // Current month's data
        let startOfMonth = previewCalendar.date(from: previewCalendar.dateComponents([.year, .month], from: now))!

        // Previous month's data
        let previousMonth = previewCalendar.date(byAdding: .month, value: -1, to: startOfMonth)!

        // Next month's data
        let nextMonth = previewCalendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        // Time entries for various periods
        let timeEntries = [
            // Current day
            TimeEntry(startTime: startOfDay.addingTimeInterval(3600 * 9), endTime: startOfDay.addingTimeInterval(3600 * 10), duration: 3600, task: task1_1),
            // Previous day
            TimeEntry(startTime: previousDay.addingTimeInterval(3600 * 8), endTime: previousDay.addingTimeInterval(3600 * 9), duration: 3600, task: task2_1),
            // Next day
            TimeEntry(startTime: nextDay.addingTimeInterval(3600 * 7), endTime: nextDay.addingTimeInterval(3600 * 8), duration: 3600, task: task3_1),
            // Current week
            TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 10), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 12), duration: 7200, task: task2_1),
            TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 2 + 3600 * 20), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 2 + 3600 * 21), duration: 3600, task: task3_1),
            TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 3 + 3600 * 14), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 3 + 3600 * 15 + 1800), duration: 5400, task: task1_1),
            TimeEntry(startTime: startOfWeek.addingTimeInterval(3600 * 24 * 4 + 3600 * 9), endTime: startOfWeek.addingTimeInterval(3600 * 24 * 4 + 3600 * 13), duration: 14400, task: task2_1),
            // Previous week
            TimeEntry(startTime: previousWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 9), endTime: previousWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 10), duration: 3600, task: task1_1),
            TimeEntry(startTime: previousWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 10), endTime: previousWeek.addingTimeInterval(3600 * 24 * 1 + 3600 * 11), duration: 3600, task: task3_1),
            // Next week
            TimeEntry(startTime: nextWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 8), endTime: nextWeek.addingTimeInterval(3600 * 24 * 0 + 3600 * 9), duration: 3600, task: task2_1),
            // Previous month
            TimeEntry(startTime: previousMonth.addingTimeInterval(3600 * 24 * 5 + 3600 * 9), endTime: previousMonth.addingTimeInterval(3600 * 24 * 5 + 3600 * 10), duration: 3600, task: task1_1),
            TimeEntry(startTime: previousMonth.addingTimeInterval(3600 * 24 * 10 + 3600 * 10), endTime: previousMonth.addingTimeInterval(3600 * 24 * 10 + 3600 * 12), duration: 7200, task: task2_1),
            // Next month
            TimeEntry(startTime: nextMonth.addingTimeInterval(3600 * 24 * 3 + 3600 * 7), endTime: nextMonth.addingTimeInterval(3600 * 24 * 3 + 3600 * 8), duration: 3600, task: task3_1)
        ]

        timeEntries.forEach { container.mainContext.insert($0) }

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
