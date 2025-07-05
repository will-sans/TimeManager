import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.orderIndex) private var projects: [Project]

    @State private var showingAddProjectSheet = false

    var body: some View {
        NavigationStack {
            List {
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
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        var updatedProjects = projects
        updatedProjects.move(fromOffsets: source, toOffset: destination)

        for index in updatedProjects.indices {
            updatedProjects[index].orderIndex = index
        }
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
