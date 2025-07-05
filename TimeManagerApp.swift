import SwiftUI
import SwiftData

@main
struct TimeManagerApp: App {
    @StateObject private var productManager = ProductManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        // String Catalog のキーをTextに直接渡す
                        Label("ProjectsTabTitle", systemImage: "folder.fill")
                    }
                
                ReportView()
                    .tabItem {
                        Label("ReportsTabTitle", systemImage: "chart.bar.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("SettingsTabTitle", systemImage: "gearshape.fill")
                    }
            }
            .environmentObject(productManager)
        }
        .modelContainer(for: [Project.self, Task.self, TimeEntry.self])
    }
}
