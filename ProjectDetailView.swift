import SwiftUI
import SwiftData
import Foundation // UUID, Date, TimeInterval を使用するため

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project // 編集可能にするため@Bindableを使用

    @State private var showingAddTaskSheet = false // タスク追加シート表示フラグ
    @State private var newProjectName: String = "" // プロジェクト名編集用
    @State private var isEditingProjectName: Bool = false // プロジェクト名編集モード

    var body: some View {
        NavigationStack {
            Form {
                // プロジェクト名編集セクション
                Section("ProjectDetails") { // Localizable.xcstringsのキー
                    HStack {
                        if isEditingProjectName {
                            TextField("ProjectName", text: $newProjectName) // Localizable.xcstringsのキー
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
                                newProjectName = project.name // 現在の名前をセット
                                isEditingProjectName = true
                            }
                        }) {
                            Image(systemName: isEditingProjectName ? "checkmark.circle.fill" : "pencil.circle.fill")
                        }
                    }
                    ColorPicker("ProjectColor", selection: Binding( // Localizable.xcstringsのキー
                        get: { Color(hex: project.colorHex) ?? .blue },
                        set: { project.colorHex = $0.toHex() ?? "#FF0000" }
                    ))
                }

                // タスク一覧セクション
                Section("Tasks") { // Localizable.xcstringsのキー
                    if let tasks = project.tasks?.sorted(by: { $0.name < $1.name }), !tasks.isEmpty {
                        ForEach(tasks) { task in
                            // タスクをタップしたらTaskDetailViewへ遷移
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .onTapGesture {
                                            task.isCompleted.toggle()
                                        }
                                    Text(task.name)
                                    Spacer()
                                    // タスクにメモがある場合、アイコンを表示
                                    if !task.memo.isEmpty {
                                        Image(systemName: "note.text")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteTasks)
                    } else {
                        ContentUnavailableView("NoTasks", systemImage: "checklist") // Localizable.xcstringsのキー
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        Label("AddTask", systemImage: "plus.circle.fill") // Localizable.xcstringsのキー
                    }
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView(project: project) // タスク追加用のシート
            }
        }
    }

    // プロジェクト名保存関数
    private func saveProjectName() {
        project.name = newProjectName
        isEditingProjectName = false
    }

    // タスク削除関数
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            if let tasks = project.tasks {
                for index in offsets {
                    modelContext.delete(tasks[index])
                }
            }
        }
    }
}

// Xcodeのプレビュー用（テストデータ）
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true) // isStoredInMemoryOnly を修正
    let container = try! ModelContainer(for: Project.self, configurations: config) // for: も修正されているはず

    let sampleProject = Project(name: "Sample Project", colorHex: "#FFC0CB", isArchived: false)
    container.mainContext.insert(sampleProject)

    let sampleTask1 = Task(name: "Sample Task 1", project: sampleProject)
    let sampleTask2 = Task(name: "Sample Task 2", memo: "This is a memo.", project: sampleProject)
    container.mainContext.insert(sampleTask1)
    container.mainContext.insert(sampleTask2)

    return ProjectDetailView(project: sampleProject)
        .modelContainer(container)
}
