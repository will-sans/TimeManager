//
//  Color+Hex.swift
//  TimeManager
//
//  Created by WILL on 2025/07/02.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        let r, g, b, a: Double
        let hexString: String

        if hex.hasPrefix("#") {
            hexString = String(hex.dropFirst())
        } else {
            hexString = hex
        }

        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return nil }

        if hexString.count == 6 {
            r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
            g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
            b = Double(hexNumber & 0x0000FF) / 255.0
            a = 1.0 // デフォルトで不透明
        } else if hexString.count == 8 {
            r = Double((hexNumber & 0xFF000000) >> 24) / 255.0
            g = Double((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = Double((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = Double(hexNumber & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
