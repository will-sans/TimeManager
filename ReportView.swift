//
//  ReportView.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI
import SwiftData

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var timeEntries: [TimeEntry] // 全ての時間記録を取得

    @State private var selectedPeriod: Period = .daily // 選択された期間（日/週/月）
    @State private var selectedDate: Date = Date() // 日別表示時の選択日付

    // 集計期間のEnum
    enum Period: String, CaseIterable, Identifiable {
        case daily = "日別"
        case weekly = "週別"
        case monthly = "月別"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 期間選択ピッカー
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 選択された期間に応じたビュー
                switch selectedPeriod {
                case .daily:
                    DailyReportView(selectedDate: $selectedDate, allTimeEntries: timeEntries)
                case .weekly:
                    Text("WeeklyReportLater")
                        .font(.title3)
                        .padding()
                    // WeeklyReportView(allTimeEntries: timeEntries) のような形で実装
                case .monthly:
                    Text("MonthlyReportLater")
                        .font(.title3)
                        .padding()
                    // MonthlyReportView(allTimeEntries: timeEntries) のような形で実装
                }

                Spacer() // コンテンツを上部に寄せる
            }
            .navigationTitle("Report")
        }
    }
}

// --- 日別レポートビュー ---
struct DailyReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date // 親ビューから選択日付を受け取る
    let allTimeEntries: [TimeEntry] // 全ての時間記録

    // 選択された日付に該当する時間記録のみをフィルタリング
    private var dailyTimeEntries: [TimeEntry] {
        allTimeEntries.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
                      .sorted(by: { $0.startTime < $1.startTime })
    }

    // プロジェクトごとの合計時間を計算
    private var aggregatedData: [String: TimeInterval] {
        var data: [String: TimeInterval] = [:]
        for entry in dailyTimeEntries {
            guard let projectName = entry.task?.project?.name else { continue }
            data[projectName, default: 0] += entry.duration
        }
        return data.sorted(by: { $0.key < $1.key }).reduce(into: [:]) { $0[$1.key] = $1.value }
    }

    // その日の合計時間
    private var totalDurationToday: TimeInterval {
        dailyTimeEntries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack {
            // 日付ナビゲーション
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

            // 今日の合計時間
            Text("TotalTodayFormat \(formattedDuration(totalDurationToday))")
                .font(.headline)
                .padding(.bottom, 5)

            // プロジェクトごとの内訳
            List {
                Section("BreakdownByProject") {
                    if aggregatedData.isEmpty {
                        Text("NoRecordsForThisDay")
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

    // 日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP") // 日本語表記に
        return formatter
    }

    // 時間をHH:MM:SS形式でフォーマットするヘルパー関数
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

    // 今日の記録
    container.mainContext.insert(TimeEntry(startTime: now.addingTimeInterval(-3600*3), endTime: now.addingTimeInterval(-3600*2), duration: 3600, task: sampleTask1))
    container.mainContext.insert(TimeEntry(startTime: now.addingTimeInterval(-3600), endTime: now.addingTimeInterval(-1800), duration: 1800, task: sampleTask3))

    // 昨日の記録
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    container.mainContext.insert(TimeEntry(startTime: yesterday.addingTimeInterval(-3600*4), endTime: yesterday.addingTimeInterval(-3600*3), duration: 3600, task: sampleTask2))
    container.mainContext.insert(TimeEntry(startTime: yesterday.addingTimeInterval(-3600*2), endTime: yesterday.addingTimeInterval(-3600*1), duration: 3600, task: sampleTask4))

    return ReportView()
        .modelContainer(container)
}
