import SwiftUI
import SwiftData
import Foundation

@main
struct TimeManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Project.self, Task.self, TimeEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            let projectCount = try container.mainContext.fetch(FetchDescriptor<Project>()).count
            if projectCount == 0 {
                print("Initial data insertion: Starting.")

                let selfGrowthProject = Project(name: "自己成長", colorHex: "#007AFF", isArchived: false, orderIndex: 0, lifeBalance: 25)
                container.mainContext.insert(selfGrowthProject)
                let readingTask = Task(name: "読書", project: selfGrowthProject)
                let learningTask = Task(name: "学習", project: selfGrowthProject)
                let introspectionTask = Task(name: "自己内省", project: selfGrowthProject)
                container.mainContext.insert(readingTask)
                container.mainContext.insert(learningTask)
                container.mainContext.insert(introspectionTask)

                let healthProject = Project(name: "健康", colorHex: "#28A745", isArchived: false, orderIndex: 1, lifeBalance: 20)
                container.mainContext.insert(healthProject)
                let sleepTask = Task(name: "睡眠", project: healthProject)
                let exerciseTask = Task(name: "運動", project: healthProject)
                let nutritionTask = Task(name: "栄養", project: healthProject)
                let meditationTask = Task(name: "瞑想", project: healthProject)
                container.mainContext.insert(sleepTask)
                container.mainContext.insert(exerciseTask)
                container.mainContext.insert(nutritionTask)
                container.mainContext.insert(meditationTask)

                let relationshipsProject = Project(name: "人間関係", colorHex: "#FFC107", isArchived: false, orderIndex: 2, lifeBalance: 25)
                container.mainContext.insert(relationshipsProject)
                let familyTimeTask = Task(name: "家族の時間", project: relationshipsProject)
                let houseworkTask = Task(name: "家事全般", project: relationshipsProject)
                let friendsTask = Task(name: "友人", project: relationshipsProject)
                container.mainContext.insert(familyTimeTask)
                container.mainContext.insert(houseworkTask)
                container.mainContext.insert(friendsTask)

                let workProject = Project(name: "仕事・創造", colorHex: "#DC3545", isArchived: false, orderIndex: 3, lifeBalance: 20)
                container.mainContext.insert(workProject)
                let dailyWorkTask = Task(name: "日常", project: workProject)
                let meetingTask = Task(name: "会議", project: workProject)
                let developmentTask = Task(name: "開発", project: workProject)
                let documentationTask = Task(name: "資料作成", project: workProject)
                container.mainContext.insert(dailyWorkTask)
                container.mainContext.insert(meetingTask)
                container.mainContext.insert(developmentTask)
                container.mainContext.insert(documentationTask)

                let hobbyProject = Project(name: "遊び・趣味", colorHex: "#6F42C1", isArchived: false, orderIndex: 4, lifeBalance: 10)
                container.mainContext.insert(hobbyProject)
                let musicTask = Task(name: "音楽", project: hobbyProject)
                let travelTask = Task(name: "旅行", project: hobbyProject)
                let gameTask = Task(name: "ゲーム", project: hobbyProject)
                let natureTask = Task(name: "自然", project: hobbyProject)
                container.mainContext.insert(musicTask)
                container.mainContext.insert(travelTask)
                container.mainContext.insert(gameTask)
                container.mainContext.insert(natureTask)

                print("Initial data insertion: Completed.")
            }
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
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
            .modelContainer(sharedModelContainer)
            .environmentObject(ProductManager()) // ProductManager が存在すればコメント解除
        }
    }
}
