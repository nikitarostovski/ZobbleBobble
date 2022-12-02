//
//  Category.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 15.02.2021.
//

import Foundation

struct Category: OptionSet {
    let rawValue: UInt32
    
    static let wall = Category(rawValue: 1 << 0)
    
    static let terrain = Category(rawValue: 1 << 1)
    static let fragment = Category(rawValue: 1 << 2)
    
    static let player = Category(rawValue: 1 << 3)
}
