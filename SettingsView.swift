//
//  SettingsView.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI
import SwiftData // SwiftDataのモデルを削除するために必要

struct SettingsView: View {
    // 週の開始曜日を保存するためのAppStorage
    // AppStorageはUserDefaultsに値を自動で保存・読み込みます
    @AppStorage("startOfWeek") var startOfWeek: Int = 1 // 1=日曜日, 2=月曜日

    // 全データリセットのアラート表示を制御するためのState
    @State private var showingResetAlert = false

    // SwiftDataのコンテキストにアクセス
    @Environment(\.modelContext) private var modelContext
    // 全てのプロジェクトを取得（データリセット時に必要となるため）
    @Query private var projects: [Project]
    
    @EnvironmentObject var productManager: ProductManager

    var body: some View {
        NavigationStack {
            Form {
                Section("一般") {
                    Picker("週の開始曜日", selection: $startOfWeek) {
                        Text("日曜日").tag(1)
                        Text("月曜日").tag(2)
                    }
                }

                Section("データ") {
                    Button("全データをリセット") {
                        showingResetAlert = true // アラートを表示する
                    }
                    .foregroundColor(.red)
                    // 全データリセットの確認アラート
                    .alert("全データを削除しますか？", isPresented: $showingResetAlert) {
                        Button("削除", role: .destructive) {
                            // MARK: - 全データ削除ロジック
                            // ここにデータを全て削除するロジックを実装します
                            // SwiftDataの場合、各モデルインスタンスを個別に削除する必要があります
                            do {
                                // TimeEntryを全て削除
                                try modelContext.delete(model: TimeEntry.self)
                                // Taskを全て削除
                                try modelContext.delete(model: Task.self)
                                // Projectを全て削除
                                try modelContext.delete(model: Project.self)

                                // または、projects @Queryで取得したものをループで削除する方法
                                // for project in projects {
                                //    modelContext.delete(project)
                                // }
                                // `delete(model:)` を使う方がシンプルです

                                // 削除が成功したことをユーザーに知らせるなどのフィードバック
                                print("全てのデータが削除されました。")
                            } catch {
                                print("データ削除中にエラーが発生しました: \(error)")
                                // エラーをユーザーに通知するなどの処理
                            }
                        }
                        Button("キャンセル", role: .cancel) { }
                    } message: {
                        Text("この操作は元に戻せません。")
                    }
                }
                Section("アプリについて") {
                    if productManager.isProVersionUnlocked {
                        Text("Proバージョンが有効です")
                            .foregroundColor(.green)
                    } else {
                        Button("Proバージョンにアップグレード（V2）") {
                            productManager.purchaseProVersion() // 未実装の購入処理を呼び出す
                        }
                    }
                    Button("購入履歴を復元") {
                        productManager.restorePurchases() // 未実装の復元処理を呼び出す
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

// SettingsView.swift の一番下にある #Preview の箇所
#Preview {
    // プレビュー用にインメモリのModelContainerを設定
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Task.self, TimeEntry.self, configurations: config)

    SettingsView()
        .modelContainer(container) // プレビューにもmodelContainerが必要
        .environmentObject(ProductManager()) // ★ここにも`.environmentObject`を追加
}
