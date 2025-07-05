import SwiftUI
import SwiftData
import Foundation

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project

    @State private var showingAddTaskSheet = false
    @State private var newProjectName: String = ""
    @State private var isEditingProjectName: Bool = false

    // プロジェクトに紐づくタスクを取得し、orderIndexでソート
    // @Query を使用せず、project.tasks をソートして使用
    private var sortedTasks: [Task] { // ★修正: プロパティ名を sortedTasks に変更
        project.tasks?.sorted(by: { $0.orderIndex < $1.orderIndex }) ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ProjectDetails") {
                    HStack {
                        if isEditingProjectName {
                            TextField("ProjectName", text: $newProjectName)
                                .onSubmit {
                                    saveProjectName()
                                }
                        } else {
                            Text(project.name)
                        }
                        Spacer()
                        Button(action: {
                            if isEditingProjectName {
                                saveProjectName()
                            } else {
                                newProjectName = project.name
                                isEditingProjectName = true
                            }
                        }) {
                            Image(systemName: isEditingProjectName ? "checkmark.circle.fill" : "pencil.circle.fill")
                        }
                    }
                    ColorPicker("ProjectColor", selection: Binding(
                        get: { Color(hex: project.colorHex) ?? .blue },
                        set: { project.colorHex = $0.toHex() ?? "#FF0000" }
                    ))

                    Stepper(value: $project.happinessWeight, in: 0...100) {
                        Text("Happiness Weight: \(project.happinessWeight)%")
                    }
                }

                Section("Tasks") {
                    if sortedTasks.isEmpty { // ★修正: tasks -> sortedTasks
                        ContentUnavailableView("NoTasks", systemImage: "checklist")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(sortedTasks) { task in // ★修正: tasks -> sortedTasks
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .onTapGesture {
                                            task.isCompleted.toggle()
                                        }
                                    Text(task.name)
                                    Spacer()
                                    if !task.memo.isEmpty {
                                        Image(systemName: "note.text")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        // ★追加: タスクの並び替え機能
                        .onMove(perform: moveTasks)
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton() // ★追加: EditButton で並び替えモードを有効に
                }
                ToolbarItem {
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        Label("AddTask", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView(project: project)
            }
        }
    }

    private func saveProjectName() {
        project.name = newProjectName
        isEditingProjectName = false
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            // 削除対象のタスクのUUIDを取得してmodelContextから削除
            let tasksToDelete = offsets.map { self.sortedTasks[$0] } // ★修正: tasks -> sortedTasks
            for task in tasksToDelete {
                modelContext.delete(task)
            }
            // 削除後に orderIndex を再割り当て
            updateTaskOrderIndices()
        }
    }

    // ★追加: タスクの並び替え関数
    private func moveTasks(from source: IndexSet, to destination: Int) {
        guard var currentTasks = project.tasks else { return } // project.tasks は元の順序（SwiftDataが保持している順序）

        // まず、現在の並び替え順（orderIndex）でソートされた配列を作成
        currentTasks.sort(by: { $0.orderIndex < $1.orderIndex })
        
        // 配列の要素を移動
        currentTasks.move(fromOffsets: source, toOffset: destination)
        
        // 移動後の新しい順序に基づいて orderIndex を再割り当て
        for index in currentTasks.indices {
            currentTasks[index].orderIndex = index
        }
        
        // project.tasks を更新してSwiftDataに反映
        // SwiftDataはリレーションシップの変更を自動的に検知し、永続化します
        project.tasks = currentTasks
    }
    
    // 削除後に orderIndex を再割り当てするためのヘルパー関数
    private func updateTaskOrderIndices() {
        guard var currentTasks = project.tasks else { return }
        currentTasks.sort(by: { $0.orderIndex < $1.orderIndex }) // 現在の順序でソート
        for index in currentTasks.indices {
            currentTasks[index].orderIndex = index // 新しいorderIndexを割り当て
        }
        project.tasks = currentTasks
    }
}
