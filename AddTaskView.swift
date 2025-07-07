import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project // 所属するプロジェクト

    @State private var taskName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("TaskName", text: $taskName)
            }
            .navigationTitle("NewTask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTask()
                    }
                    .disabled(taskName.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let newOrderIndex = (project.tasks?.max(by: { $0.orderIndex < $1.orderIndex })?.orderIndex ?? -1) + 1
        
        // ★修正: Taskの初期化からmemo, satisfactionScore, categoryを削除
        let newTask = Task(name: taskName,
                           isCompleted: false,
                           orderIndex: newOrderIndex,
                           project: project)
        modelContext.insert(newTask)
        dismiss()
    }
}

// Xcodeのプレビュー用（テストデータ）
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)
        
        let sampleProject = Project(name: "Sample Project", colorHex: "#FFC0CB", isArchived: false, lifeBalance: 20)
        container.mainContext.insert(sampleProject)

        return AddTaskView(project: sampleProject)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }
}
