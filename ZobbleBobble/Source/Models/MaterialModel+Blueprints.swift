//
//  MaterialModel+Blueprints.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation
import Blueprints

extension MaterialType {
    public var categoryMask: MaterialCategory {
        switch self {
        case .soil: return [.solid]
        case .sand: return [.solid, .dust]
        case .rock: return [.solid]
        case .water: return [.liquid]
        case .oil: return [.liquid]
        }
    }
    
    static func getMaterials(for categories: [MaterialCategory]) -> [MaterialType] {
        MaterialType.allCases.filter { material in
            categories.firstIndex(where: { material.categoryMask.contains($0) }) != nil
        }
    }
}
