//
//  Material.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import UIKit

public enum MaterialType: CaseIterable {
    case solid
    case breakable
}

public class Material {
    public let type: MaterialType
    
//    public var minSplitDistance: CGFloat {
//        switch type {
//        case .water:
//            return 4
//        case .rock:
//            return 12
//        }
//    }
    
    public init(type: MaterialType) {
        self.type = type
    }
    
    public init?(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        guard alpha > 0.5 else { return nil }
        
        switch red {
        case 0...0.5:
            self.type = .solid
        default:
            self.type = .breakable
        }
    }
}
