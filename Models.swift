import Foundation
import SwiftData

// プロジェクトモデル
@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: String
    var isArchived: Bool
    var orderIndex: Int
    var lifeBalance: Int // ★名称変更: happinessWeight -> lifeBalance
    // プロジェクトがライフバランス（カテゴリ）の役割を担う

    @Relationship(deleteRule: .cascade) var tasks: [Task]?

    init(id: UUID = UUID(), name: String, colorHex: String, isArchived: Bool = false, orderIndex: Int = 0, lifeBalance: Int = 0) { // ★initも修正
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.orderIndex = orderIndex
        self.lifeBalance = lifeBalance // 初期化
    }
}

// タスクモデル（変更なし）
@Model
final class Task {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var memo: String
    var satisfactionScore: Int?
    var orderIndex: Int // タスクの並び順を保持するプロパティ
    
    @Relationship var project: Project?
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]?

    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, memo: String = "", satisfactionScore: Int? = nil, orderIndex: Int = 0, project: Project? = nil) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.memo = memo
        self.satisfactionScore = satisfactionScore
        self.orderIndex = orderIndex
        self.project = project
    }
}

// 時間記録モデル（変更なし）
@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var memo: String
    @Relationship var task: Task?

    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, duration: TimeInterval = 0, memo: String = "", task: Task? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.memo = memo
    }
}
