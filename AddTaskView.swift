import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project

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
        // 新しいタスクを作成
        let newTask = Task(
            name: taskName,
            isCompleted: false,
            orderIndex: 0, // 仮の orderIndex。あとで更新
            project: project
        )

        // SwiftData に挿入
        modelContext.insert(newTask)

        // project.tasks に明示的に追加
        if project.tasks == nil {
            project.tasks = [newTask]
        } else {
            project.tasks?.append(newTask)
        }

        // orderIndex を再割り当て（ソート後に正確な順序を保証）
        if var tasks = project.tasks {
            tasks.sort { $0.orderIndex < $1.orderIndex }
            for (index, task) in tasks.enumerated() {
                task.orderIndex = index
            }
            project.tasks = tasks
        }

        dismiss()
    }
}

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
