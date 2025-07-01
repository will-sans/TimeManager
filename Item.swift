//
//  Item.swift
//  TimeManager
//
//  Created by WILL on 2025/06/30.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
