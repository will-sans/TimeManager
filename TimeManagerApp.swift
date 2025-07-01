//
//  TimeManagerApp.swift
//  TimeManager
//
//  Created by WILL on 2025/06/30.
//

import SwiftUI
import SwiftData // 追加

@main
struct TimeManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self]) // ここを追加
    }
}
