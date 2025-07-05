import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.orderIndex) private var projects: [Project]

    @State private var showingAddProjectSheet = false

    // 全プロジェクトのライフバランス合計
    private var totalLifeBalance: Int {
        projects.reduce(0) { $0 + $1.lifeBalance }
    }

    var body: some View {
        NavigationStack {
            List {
                // ライフバランス合計表示
                Section {
                    HStack {
                        Text("Total Life Balance:") // Localizable.xcstrings にキーを追加
                        Spacer()
                        Text("\(totalLifeBalance)%")
                            .foregroundColor(totalLifeBalance == 100 ? .green : .red) // 100%なら緑
                    }
                    Text("Adjust LifeBalance to 100%.") // Localizable.xcstrings にキーを追加
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if projects.isEmpty {
                    ContentUnavailableView("NoProjects", systemImage: "folder")
                        .padding()
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    ForEach(projects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: project.colorHex) ?? .blue)
                                    .frame(width: 10, height: 10)
                                Text(project.name)
                                Spacer()
                                // LifeBalance 調整用 Stepper
                                Stepper(value: Binding(
                                    get: { project.lifeBalance },
                                    set: { newValue in
                                        // 合計が100%を超えないように制御
                                        // またはユーザーに任せるか、他のプロジェクトを調整するか
                                        // 今回は単にSteppperの範囲で制御
                                        if totalLifeBalance - project.lifeBalance + newValue <= 100 {
                                            project.lifeBalance = newValue
                                        } else {
                                            // 100%を超えそうになったら最大値を100%に制限
                                            project.lifeBalance = 100 - (totalLifeBalance - project.lifeBalance)
                                        }
                                    }
                                ), in: 0...100) { // 0%から100%の範囲
                                    Text("\(project.lifeBalance)%")
                                }
                                .fixedSize() // Stepperが横幅を広げすぎないように
                            }
                        }
                    }
                    .onMove(perform: moveProjects)
                    .onDelete(perform: deleteProjects)
                }
            }
            .navigationTitle("ProjectsTabTitle")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        showingAddProjectSheet = true
                    }) {
                        Label("AddProject", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddProjectSheet) {
                AddProjectView()
            }
        }
    }

    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
            // 削除後に orderIndex を再割り当て
            updateProjectOrderIndices()
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        var updatedProjects = projects
        updatedProjects.move(fromOffsets: source, toOffset: destination)

        for index in updatedProjects.indices {
            updatedProjects[index].orderIndex = index
        }
        // SwiftDataは変更を自動的に検知し保存します
    }

    // 削除後に orderIndex を再割り当てするためのヘルパー
    private func updateProjectOrderIndices() {
        var currentProjects = projects // @Queryの結果は自動更新されるので、念のためコピー
        currentProjects.sort(by: { $0.orderIndex < $1.orderIndex }) // 現在の順序でソート
        for index in currentProjects.indices {
            currentProjects[index].orderIndex = index // 新しいorderIndexを割り当て
        }
        // project.tasks は @Relationship なので、project.tasks = currentProjects で更新される
        // Query results in SwiftUI are @State var internally, so assigning to them directly can trigger update.
    }
}
// AddProjectView のコードは変更なし（前回の正しいコードを使用）
struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var projects: [Project]

    @State private var projectName: String = ""
    @State private var projectColor: Color = .red

    let categories = ["General", "Work", "Learning", "Health", "Relationships", "Hobby", "Entertainment"]

    var body: some View {
        NavigationView {
            Form {
                TextField("ProjectName", text: $projectName)
                ColorPicker("ProjectColor", selection: $projectColor)
            }
            .navigationTitle("NewProject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addProject()
                    }
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }

    private func addProject() {
        let newOrderIndex = projects.count
        let newProject = Project(name: projectName, colorHex: projectColor.toHex() ?? "#FF0000", orderIndex: newOrderIndex)
        modelContext.insert(newProject)
        dismiss()
    }
}

// MARK: - Previews
// Xcodeのプレビュー用（テストデータ）
#Preview {
    // ★修正: ModelContainerを直接 for: に渡す形で簡潔に記述
    // isStoredInMemoryOnly: true を設定してメモリ内データベースを使用
    ContentView()
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self], inMemory: true)
}
