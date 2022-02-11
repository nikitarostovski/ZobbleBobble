//
//  Compound.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 16.01.2022.
//

import UIKit

enum Material {
    case rock
    case tnt
    case core
}

extension Material {
    var color: UIColor {
        switch self {
        case .rock:
            return .blue
        case .tnt:
            return .orange
        case .core:
            return .cyan
        }
    }
}
