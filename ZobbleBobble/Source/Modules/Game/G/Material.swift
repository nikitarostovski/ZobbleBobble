//
//  Material.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import UIKit

enum MaterialType: CaseIterable {
    case sand
    case rock
    case obsidian
}

class Material {
    let type: MaterialType
    var color: UIColor {
        switch type {
        case .sand:
            return .orange
        case .rock:
            return .lightGray
        case .obsidian:
            return .darkGray
        }
    }
    
    init(type: MaterialType) {
        self.type = type
    }
}
