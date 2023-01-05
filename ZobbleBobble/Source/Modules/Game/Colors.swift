//
//  Colors.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation

enum Colors {
    static let coreColors: [CGRect] = [
        CGRect(x: 255, y: 245, width: 225, height: 0),
    ]
    static let liquidCometColors: [CGRect] = [
        CGRect(x: 255, y: 37, width: 0, height: 0),
        CGRect(x: 255, y: 102, width: 0, height: 0),
        CGRect(x: 242, y: 242, width: 23, height: 0)
    ]
    static let solidCometColots: [CGRect] = [
        CGRect(x: 100, y: 200, width: 170, height: 0),
    ]
    
    case comet(CometType)
    case core
    
    func pickColor() -> CGRect {
        switch self {
        case .core:
            return Self.coreColors.randomElement()!
        case .comet(let type):
            switch type {
            case .liquid:
                return Self.liquidCometColors.randomElement()!
            case .solid:
                return Self.solidCometColots.randomElement()!
            }
        }
    }
}

extension CGRect {
    var simdColor: SIMD4<UInt8> {
        return SIMD4<UInt8>(UInt8(origin.x), UInt8(origin.y), UInt8(size.width), UInt8(size.height))
    }
}
