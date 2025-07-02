//
//  TimeManagerApp.swift
//  TimeManager
//
//  Created by WILL on 2025/06/30.
//

import SwiftUI
import SwiftData

@main
struct TimeManagerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView { // ここをTabViewに変更
                ContentView() // プロジェクトリスト
                    .tabItem {
                        Label("プロジェクト", systemImage: "folder.fill")
                    }

                ReportView() // レポートビュー
                    .tabItem {
                        Label("レポート", systemImage: "chart.bar.fill")
                    }

                // 設定ビューもここに将来的に追加
                SettingsView() // ここをText(...)から変更
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
            }
        }
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self])
    }
}
