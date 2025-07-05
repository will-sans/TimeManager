import Foundation
import SwiftData

// プロジェクトモデル（カテゴリとしての役割を強化）
@Model
final class Project {
    var id: UUID
    var name: String // プロジェクト名（＝カテゴリ名）
    var colorHex: String // カテゴリの色
    var isArchived: Bool // アーカイブ済みかどうかのフラグ
    var orderIndex: Int // プロジェクト/カテゴリの並び順

    // ★追加: 幸せの要素のウェイト（パーセンテージ）
    // ユーザーが設定する「理想のポートフォリオ」の重み
    var happinessWeight: Int // 0-100のパーセンテージ

    @Relationship(deleteRule: .cascade) var tasks: [Task]? // 関連するタスク

    init(id: UUID = UUID(), name: String, colorHex: String, isArchived: Bool = false, orderIndex: Int = 0, happinessWeight: Int = 0) { // ★initも修正
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.orderIndex = orderIndex
        self.happinessWeight = happinessWeight // 初期化
    }
}

// タスクモデル
@Model
final class Task {
    var id: UUID
    var name: String
    var isCompleted: Bool // 完了済みかどうかのフラグ
    var memo: String // タスクのメモ
    // var category: String // ★削除: Projectがカテゴリの役割を担うため不要
    var satisfactionScore: Int? // 完了時の満足度（1-10、Optionalで）
    
    @Relationship var project: Project? // 所属するプロジェクト
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]? // 関連する時間記録

    // ★initを修正: category引数を削除
    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, memo: String = "", satisfactionScore: Int? = nil, project: Project? = nil) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.memo = memo
        self.satisfactionScore = satisfactionScore
        self.project = project
    }
}

// 時間記録モデル（変更なし）
@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date? // 終了時刻がない場合はnil（計測中の状態）
    var duration: TimeInterval // 計測時間（秒単位）
    var memo: String // メモ
    @Relationship var task: Task? // 関連するタスク

    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, duration: TimeInterval = 0, memo: String = "", task: Task? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.memo = memo
    }
}
