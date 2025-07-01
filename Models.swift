//
//  Models.swift
//  TimeManager
//
//  Created by WILL on 2025/07/01.
//

import Foundation
import SwiftData // iOS 17以降の場合

// プロジェクトモデル
@Model
final class Project {
    var name: String
    var colorHex: String // 色を保存するためのHEXコード（例: "#FF0000"）
    var isArchived: Bool // アーカイブ済みかどうかのフラグ
    @Relationship(deleteRule: .cascade) var tasks: [Task]? // 関連するタスク

    init(name: String, colorHex: String, isArchived: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
    }
}

// タスクモデル
@Model
final class Task {
    var name: String
    var isCompleted: Bool // 完了済みかどうかのフラグ
    @Relationship var project: Project? // 所属するプロジェクト
    @Relationship(deleteRule: .cascade) var timeEntries: [TimeEntry]? // 関連する時間記録

    init(name: String, isCompleted: Bool = false, project: Project? = nil) {
        self.name = name
        self.isCompleted = isCompleted
        self.project = project
    }
}

// 時間記録モデル
@Model
final class TimeEntry {
    var startTime: Date
    var endTime: Date? // 終了時刻がない場合はnil（計測中の状態）
    var duration: TimeInterval // 計測時間（秒単位）
    var memo: String // メモ
    @Relationship var task: Task? // 関連するタスク

    init(startTime: Date, endTime: Date? = nil, duration: TimeInterval = 0, memo: String = "", task: Task? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.memo = memo
    }
}
