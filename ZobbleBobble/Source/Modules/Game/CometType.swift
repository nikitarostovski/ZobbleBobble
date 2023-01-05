//
//  CometType.swift
//  ZobbleBobble
//
//  Created by Rost on 31.12.2022.
//

import Foundation

enum CometType {
    case liquid
    case solid
    
    var radius: CGFloat {
        switch self {
        case .solid: return 7
        case .liquid: return 15
        }
    }
}
