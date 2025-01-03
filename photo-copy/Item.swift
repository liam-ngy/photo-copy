//
//  Item.swift
//  photo-copy
//
//  Created by Liam Nguyen on 3/1/2025.
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
