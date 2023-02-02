//
//  Material.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import UIKit

public enum Material {
    case lavaRed
    case lavaYellow
    case bomb
    
    public var color: SIMD4<UInt8> {
        switch self {
        case .lavaRed:
            return SIMD4<UInt8>(255, 96, 64, 255)
        case .lavaYellow:
            return SIMD4<UInt8>(220, 185, 10, 255)
        case .bomb:
            return SIMD4<UInt8>(100, 200, 170, 255)
        }
    }
    
    public var missleRadius: CGFloat {
        switch self {
        case .lavaRed:
            return 15
        case .lavaYellow:
            return 15
        case .bomb:
            return 5
        }
    }
    
    public var weight: Float {
        1
    }
}
