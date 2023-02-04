//
//  MaterialModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public enum MaterialType: String, Codable {
    case lavaRed
    case lavaYellow
    case bomb
    case coreLight
    case coreDark
    
    public var color: SIMD4<UInt8> {
        switch self {
        case .lavaRed:
            return SIMD4<UInt8>(255, 96, 64, 255)
        case .lavaYellow:
            return SIMD4<UInt8>(220, 185, 10, 255)
        case .bomb:
            return SIMD4<UInt8>(100, 200, 170, 255)
        case .coreLight:
            return SIMD4<UInt8>(200, 200, 200, 255)
        case .coreDark:
            return SIMD4<UInt8>(100, 100, 100, 255)
        }
    }
}
