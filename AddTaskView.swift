import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project // 所属するプロジェクト

    @State private var taskName: String = ""
    // ★削除: @State private var selectedCategory: String = "General"
    // ★削除: let categories = [...]

    var body: some View {
        NavigationView {
            Form {
                TextField("TaskName", text: $taskName)

                // ★削除: カテゴリ選択ピッカー
                // Picker("Category", selection: $selectedCategory) {
                //     ForEach(categories, id: \.self) { category in
                //         Text(category).tag(category)
                //     }
                // }
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
        // ★修正: category引数を削除
        let newTask = Task(name: taskName,
                           isCompleted: false,
                           memo: "",
                           satisfactionScore: nil, // OptionalなのでnilでOK
                           project: project)
        modelContext.insert(newTask)
        project.tasks?.append(newTask)
        dismiss()
    }
}

// Xcodeのプレビュー用（テストデータ）
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)
        
        // ★修正: ProjectにhappinessWeightを追加
        let sampleProject = Project(name: "Sample Project", colorHex: "#FFC0CB", isArchived: false, happinessWeight: 20)
        container.mainContext.insert(sampleProject)

        return AddTaskView(project: sampleProject)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create ModelContainer for preview: \(error)")
    }
}
