import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext // SwiftDataのコンテキストにアクセス
    @Query(sort: \Project.name) private var projects: [Project] // 全てのプロジェクトを取得

    @State private var showingAddProjectSheet = false // プロジェクト追加シート表示フラグ

    var body: some View {
        NavigationStack {
            List {
                // プロジェクトがなければメッセージを表示
                if projects.isEmpty {
                    ContentUnavailableView("プロジェクトがありません", systemImage: "folder")
                        .padding()
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    // プロジェクトの一覧を表示
                    ForEach(projects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            Text(project.name)
                        }
                    }
                    .onDelete(perform: deleteProjects) // スワイプで削除
                }
            }
            .navigationTitle("プロジェクト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton() // 編集ボタン（並び替えや複数削除用）
                }
                ToolbarItem {
                    Button(action: {
                        showingAddProjectSheet = true // プロジェクト追加シートを表示
                    }) {
                        Label("プロジェクトを追加", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddProjectSheet) {
                AddProjectView() // プロジェクト追加用のシート
            }
        }
    }

    // プロジェクト削除関数
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}

// 新しいプロジェクトを追加するためのビュー
struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // シートを閉じるため

    @State private var projectName: String = ""
    // プロジェクトの色選択用（シンプルに赤を設定）
    // 実際にはカラーピッカーなどを実装する
    @State private var projectColor: Color = .red

    var body: some View {
        NavigationView {
            Form {
                TextField("プロジェクト名", text: $projectName)
                // 仮の色選択（実際はよりリッチなUIに）
                ColorPicker("プロジェクトの色", selection: $projectColor)
            }
            .navigationTitle("新しいプロジェクト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addProject()
                    }
                    .disabled(projectName.isEmpty) // プロジェクト名が空の場合は保存ボタンを無効化
                }
            }
        }
    }

    private func addProject() {
        let newProject = Project(name: projectName, colorHex: projectColor.toHex() ?? "#FF0000") // ColorをHex文字列に変換
        modelContext.insert(newProject) // モデルコンテキストに挿入
        dismiss() // シートを閉じる
    }
}

// ColorをHEX文字列に変換するヘルパー拡張（簡易版）
// 実際にはより堅牢な実装が必要
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// Xcodeのプレビュー用（テストデータ）
#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self], inMemory: true) // プレビュー用にメモリ内データベースを使用
}
