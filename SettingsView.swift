import SwiftUI
import SwiftData // SwiftDataのモデルを削除するために必要

struct SettingsView: View {
    @AppStorage("startOfWeek") var startOfWeek: Int = 1 // 1=日曜日, 2=月曜日

    @State private var showingResetAlert = false

    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    
    @EnvironmentObject var productManager: ProductManager

    var body: some View {
        NavigationStack {
            Form {
                Section("General") { // Localizable.xcstringsにキーを追加
                    Picker("StartOfWeek", selection: $startOfWeek) { // Localizable.xcstringsにキーを追加
                        Text("Sunday").tag(1) // Localizable.xcstringsにキーを追加
                        Text("Monday").tag(2) // Localizable.xcstringsにキーを追加
                    }
                }

                Section("Data") { // Localizable.xcstringsにキーを追加
                    Button("ResetAllData") { // Localizable.xcstringsにキーを追加
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .alert("DeleteAllDataConfirmation", isPresented: $showingResetAlert) { // Localizable.xcstringsにキーを追加
                        Button("Delete", role: .destructive) { // Localizable.xcstringsにキーを追加
                            do {
                                try modelContext.delete(model: TimeEntry.self)
                                try modelContext.delete(model: Task.self)
                                try modelContext.delete(model: Project.self)

                                print("全てのデータが削除されました。")
                            } catch {
                                print("データ削除中にエラーが発生しました: \(error)")
                            }
                        }
                        Button("Cancel", role: .cancel) { } // Localizable.xcstringsにキーを追加
                    } message: {
                        Text("ThisActionCannotBeUndone") // Localizable.xcstringsにキーを追加
                    }
                }
                Section("AboutApp") { // Localizable.xcstringsにキーを追加
                    if productManager.isProVersionUnlocked {
                        Text("ProVersionEnabled") // Localizable.xcstringsにキーを追加
                            .foregroundColor(.green)
                    } else {
                         Button("UpgradeToProVersionV2") { // Localizable.xcstringsにキーを追加
                            productManager.purchaseProVersion()
                        }
                    }
                    Button("RestorePurchases") { // Localizable.xcstringsにキーを追加
                        productManager.restorePurchases()
                    }
                    Text("AboutApp_Placeholder") // 仮のテキスト。ローカライズキーに置き換える
                }
            }
            .navigationTitle("SettingsTabTitle") // Localizable.xcstringsにキーを追加
        }
    }
}

// SettingsView.swift の一番下にある #Preview の箇所
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    SettingsView()
        .modelContainer(container)
        .environmentObject(ProductManager())
}
