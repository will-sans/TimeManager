//
//  SettingsView.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("一般") {
                    Text("週の開始曜日（後で実装）")
                    Text("時間の表示形式（後で実装）")
                }
                Section("データ") {
                    Button("全データをリセット（後で実装）") {
                        // アラートなどで確認を促す
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
