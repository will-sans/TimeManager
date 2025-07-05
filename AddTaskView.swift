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
        // 新しいタスクのorderIndexを設定
        // 現在のタスクの最大orderIndex + 1 を新しいorderIndexとする
        // もしタスクが一つもなければ0とする
        let newOrderIndex = (project.tasks?.max(by: { $0.orderIndex < $1.orderIndex })?.orderIndex ?? -1) + 1
        
        let newTask = Task(name: taskName,
                           isCompleted: false,
                           memo: "",
                           satisfactionScore: nil,
                           orderIndex: newOrderIndex, // ★修正: orderIndexを設定
                           project: project)
        modelContext.insert(newTask)
        // project.tasks?.append(newTask) // @Relationship で自動的に追加されるため、明示的な追加は不要
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
