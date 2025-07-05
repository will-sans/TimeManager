import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var timeEntries: [TimeEntry]

    @State private var selectedPeriod: Period = .daily
    @State private var selectedDate: Date = Date()

    enum Period: String, CaseIterable, Identifiable {
        case daily = "日別" // Localizable.xcstringsにキーを追加
        case weekly = "週別" // Localizable.xcstringsにキーを追加
        case monthly = "月別" // Localizable.xcstringsにキーを追加
        var id: String { self.rawValue } // ローカライズキーとしてrawValueを使うのは推奨されないが、一旦そのまま
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Period", selection: $selectedPeriod) { // Localizable.xcstringsにキーを追加
                    ForEach(Period.allCases) { period in
                        Text(LocalizedStringKey(period.rawValue)).tag(period) // ★修正: LocalizedStringKey を使用
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedPeriod {
                case .daily:
                    DailyReportView(selectedDate: $selectedDate, allTimeEntries: timeEntries)
                case .weekly:
                    Text("WeeklyReportLater") // Localizable.xcstringsにキーを追加
                        .font(.title3)
                        .padding()
                case .monthly:
                    Text("MonthlyReportLater") // Localizable.xcstringsにキーを追加
                        .font(.title3)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("ReportsTabTitle") // Localizable.xcstringsにキーを追加
        }
    }
}

// --- 日別レポートビュー ---
struct DailyReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date
    let allTimeEntries: [TimeEntry]

    private var dailyTimeEntries: [TimeEntry] {
        allTimeEntries.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
                     .sorted(by: { $0.startTime < $1.startTime })
    }

    private var aggregatedData: [String: TimeInterval] {
        var data: [String: TimeInterval] = [:]
        for entry in dailyTimeEntries {
            guard let projectName = entry.task?.project?.name else { continue }
            data[projectName, default: 0] += entry.duration
        }
        return data.sorted(by: { $0.key < $1.key }).reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    private var totalDurationToday: TimeInterval {
        dailyTimeEntries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(selectedDate, formatter: dateFormatter)
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            Text("TotalTodayFormat \(formattedDuration(totalDurationToday))") // Localizable.xcstringsにキーを追加
                .font(.headline)
                .padding(.bottom, 5)

            List {
                Section("BreakdownByProject") { // Localizable.xcstringsにキーを追加
                    if aggregatedData.isEmpty {
                        Text("NoRecordsForThisDay") // Localizable.xcstringsにキーを追加
                            .foregroundColor(.gray)
                    } else {
                        ForEach(aggregatedData.keys.sorted(), id: \.self) { projectName in
                            HStack {
                                Text(projectName)
                                Spacer()
                                Text(formattedDuration(aggregatedData[projectName] ?? 0))
                            }
                        }
                    }
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}


// Xcodeのプレビュー用（ダミーデータ）
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    // ダミーデータをコンテナに挿入
    let sampleProject1 = Project(name: "企画書作成", colorHex: "#FF6347")
    let sampleTask1 = Task(name: "要件定義", project: sampleProject1)
    let sampleTask2 = Task(name: "デザインレビュー", project: sampleProject1)

    let sampleProject2 = Project(name: "開発", colorHex: "#4682B4")
    let sampleTask3 = Task(name: "UIコーディング", project: sampleProject2)
    let sampleTask4 = Task(name: "バグ修正", project: sampleProject2)

    let now = Date()
    container.mainContext.insert(sampleProject1)
    container.mainContext.insert(sampleProject2)
    container.mainContext.insert(sampleTask1)
    container.mainContext.insert(sampleTask2)
    container.mainContext.insert(sampleTask3)
    container.mainContext.insert(sampleTask4)

    container.mainContext.insert(TimeEntry(startTime: now.addingTimeInterval(-3600*3), endTime: now.addingTimeInterval(-3600*2), duration: 3600, task: sampleTask1))
    container.mainContext.insert(TimeEntry(startTime: now.addingTimeInterval(-3600), endTime: now.addingTimeInterval(-1800), duration: 1800, task: sampleTask3))

    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    container.mainContext.insert(TimeEntry(startTime: yesterday.addingTimeInterval(-3600*4), endTime: yesterday.addingTimeInterval(-3600*3), duration: 3600, task: sampleTask2))
    container.mainContext.insert(TimeEntry(startTime: yesterday.addingTimeInterval(-3600*2), endTime: yesterday.addingTimeInterval(-3600*1), duration: 3600, task: sampleTask4))

    return ReportView()
        .modelContainer(container)
}
