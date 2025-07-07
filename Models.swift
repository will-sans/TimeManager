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
    var lifeBalance: Int

    @Relationship(deleteRule: .cascade) var tasks: [Task]?

    init(id: UUID = UUID(), name: String, colorHex: String, isArchived: Bool = false, orderIndex: Int = 0, lifeBalance: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.orderIndex = orderIndex
        self.lifeBalance = lifeBalance
    }
}

// タスクモデル
@Model
final class Task {
    var id: UUID
    var name: String
    var isCompleted: Bool
    // var memo: String // ★削除: memoをTimeEntryへ移動
    // var satisfactionScore: Int? // ★削除: satisfactionScoreをTimeEntryへ移動
    var orderIndex: Int
    
    @Relationship var project: Project?
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]?

    // ★initを修正: memoとsatisfactionScore引数を削除
    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, orderIndex: Int = 0, project: Project? = nil) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
        self.project = project
    }
}

// 時間記録モデル
@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var memo: String // ★追加: memoをTimeEntryへ移動
    var satisfactionScore: Int? // ★追加: satisfactionScoreをTimeEntryへ移動
    @Relationship var task: Task?

    // ★initを修正: memoとsatisfactionScore引数を追加
    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, duration: TimeInterval = 0, memo: String = "", satisfactionScore: Int? = nil, task: Task? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.memo = memo
        self.satisfactionScore = satisfactionScore
        self.task = task
    }
}
