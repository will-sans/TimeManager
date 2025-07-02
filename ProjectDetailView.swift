//
//  ProjectDetailView.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project // 選択されたプロジェクトを受け取る

    @State private var showingAddTaskSheet = false // タスク追加シート表示フラグ

    // プロジェクトに紐づくタスクを取得
    // @QueryはSwiftDataのクエリで、project.tasksがnilでない場合にのみ実行されます。
    // project.tasksが@RelationshipでOptionalなので、nilチェックが必要です。
    // あるいは、ProjectモデルのtasksをOptionalでない配列にし、initで空配列を渡す方法もあります。
    // ここではシンプルに、project.tasksがnilの場合に空の配列を返すようにします。
    private var tasks: [Task] {
        project.tasks?.sorted(by: { $0.name < $1.name }) ?? []
    }

    var body: some View {
        List {
            // タスクがなければメッセージを表示
            if tasks.isEmpty {
                ContentUnavailableView("タスクがありません", systemImage: "checklist")
                    .padding()
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                // タスクの一覧を表示
                ForEach(tasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) { // 後でTaskDetailViewを作成します
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    task.isCompleted.toggle() // タスクの完了状態を切り替える
                                }
                            Text(task.name)
                            Spacer()
                            // タスクの合計時間を表示（後で実装）
                            Text("合計時間: \(formattedDuration(for: task))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteTasks) // スワイプで削除
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: {
                    showingAddTaskSheet = true // タスク追加シートを表示
                }) {
                    Label("タスクを追加", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddTaskSheet) {
            AddTaskView(project: project) // タスク追加用のシート
        }
    }

    // タスク削除関数
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }

    // タスクの合計時間をフォーマットするヘルパー関数（仮）
    private func formattedDuration(for task: Task) -> String {
        let totalDuration = task.timeEntries?.reduce(0) { $0 + $1.duration } ?? 0
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// 新しいタスクを追加するためのビュー
struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project // どのプロジェクトにタスクを追加するか

    @State private var taskName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("タスク名", text: $taskName)
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addTask()
                    }
                    .disabled(taskName.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let newTask = Task(name: taskName, project: project)
        modelContext.insert(newTask)
        project.tasks?.append(newTask) // プロジェクトにもタスクを追加（リレーションシップの更新）
        dismiss()
    }
}

// Xcodeのプレビュー用
#Preview {
    // プレビュー用にダミーデータを作成
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    let sampleProject = Project(name: "サンプルプロジェクト", colorHex: "#007AFF")
    let sampleTask1 = Task(name: "タスクA", project: sampleProject)
    let sampleTask2 = Task(name: "タスクB", isCompleted: true, project: sampleProject)
    sampleProject.tasks = [sampleTask1, sampleTask2] // タスクをプロジェクトに紐付け

    return ProjectDetailView(project: sampleProject)
        .modelContainer(container)
}
