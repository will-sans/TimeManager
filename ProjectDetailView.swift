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

    private var sortedTasks: [Task] {
        project.tasks?.sorted(by: { $0.orderIndex < $1.orderIndex }) ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                projectDetailsSection // プロジェクト詳細セクションを切り出し
                tasksSection // タスクセクションを切り出し
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
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

    // MARK: - ViewBuilder プロパティでセクションを分割

    @ViewBuilder
    private var projectDetailsSection: some View {
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
        }
    }

    @ViewBuilder
    private var tasksSection: some View {
        Section("Tasks") {
            if sortedTasks.isEmpty {
                ContentUnavailableView("NoTasks", systemImage: "checklist")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(sortedTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    task.isCompleted.toggle()
                                }
                            Text(task.name)
                            Spacer()
                            // task.memo は TimeEntry に移動したので、task.memo は常に空になるはずです
                            // TimeEntry のメモを表示するには、TaskDetailView 内の TimeEntry リストで確認します。
                            // ここは Task 自体のメモではなくなったため、表示を削除します。
                            // if !task.memo.isEmpty {
                            //     Image(systemName: "note.text")
                            //         .font(.caption)
                            //         .foregroundColor(.gray)
                            // }
                        }
                    }
                }
                .onMove(perform: moveTasks)
                .onDelete(perform: deleteTasks)
            }
        }
    }

    // MARK: - Helper Functions

    private func saveProjectName() {
        project.name = newProjectName
        isEditingProjectName = false
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            let tasksToDelete = offsets.map { self.sortedTasks[$0] }
            for task in tasksToDelete {
                modelContext.delete(task)
            }
            updateTaskOrderIndices()
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        guard var currentTasks = project.tasks else { return }
        currentTasks.sort(by: { $0.orderIndex < $1.orderIndex })
        currentTasks.move(fromOffsets: source, toOffset: destination)
        for index in currentTasks.indices {
            currentTasks[index].orderIndex = index
        }
        project.tasks = currentTasks
    }
    
    private func updateTaskOrderIndices() {
        guard var currentTasks = project.tasks else { return }
        currentTasks.sort(by: { $0.orderIndex < $1.orderIndex })
        for index in currentTasks.indices {
            currentTasks[index].orderIndex = index
        }
        project.tasks = currentTasks
    }
}
