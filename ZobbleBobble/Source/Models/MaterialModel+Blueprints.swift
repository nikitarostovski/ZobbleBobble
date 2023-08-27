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
        case .organic, .rock, .metal, .magma:
            return [.solid]
        case .acid, .water, .oil:
            return [.liquid]
        case .sand, .dust:
            return [.solid, .dust]
        }
    }
    
    static func getMaterials(for categories: [MaterialCategory]) -> [MaterialType] {
        MaterialType.allCases.filter { material in
            categories.firstIndex(where: { material.categoryMask.contains($0) }) != nil
        }
    }
}
