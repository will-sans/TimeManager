//
//  Color+Hex.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI
import UIKit // UIColorを使用するため

extension Color {
    // MARK: - Initializer from Hex String
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0 // Default to opaque
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    // MARK: - Convert to Hex String
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else { return nil }

        // RGBAのコンポーネントを取得。alphaがcomponents[3]に存在する場合もある
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        // アルファ値も必要なら components.count == 4 をチェックして a = Float(components[3])
        // 今回はRGBのみで良いので、アルファは考慮しない

        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
