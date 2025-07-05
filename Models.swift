import Foundation
import SwiftData

// プロジェクトモデル（変更なし）
@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: String
    var isArchived: Bool
    var orderIndex: Int
    var happinessWeight: Int

    @Relationship(deleteRule: .cascade) var tasks: [Task]?

    init(id: UUID = UUID(), name: String, colorHex: String, isArchived: Bool = false, orderIndex: Int = 0, happinessWeight: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.orderIndex = orderIndex
        self.happinessWeight = happinessWeight
    }
}

// タスクモデル
@Model
final class Task {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var memo: String
    var satisfactionScore: Int?
    var orderIndex: Int // ★追加: タスクの並び順を保持するプロパティ
    
    @Relationship var project: Project?
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]?

    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, memo: String = "", satisfactionScore: Int? = nil, orderIndex: Int = 0, project: Project? = nil) { // ★initも修正
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.memo = memo
        self.satisfactionScore = satisfactionScore
        self.orderIndex = orderIndex // 初期化
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
