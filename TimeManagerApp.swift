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
    // ProductManagerのインスタンスを作成
    @StateObject private var productManager = ProductManager() // ★ここに `@StateObject` を追加

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("プロジェクト", systemImage: "folder.fill")
                    }
                
                ReportView()
                    .tabItem {
                        Label("レポート", systemImage: "chart.bar.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
            }
            .environmentObject(productManager) // ★ここに `.environmentObject` を追加
        }
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self])
    }
}
