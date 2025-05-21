//
//  Item.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 21/05/25.
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
