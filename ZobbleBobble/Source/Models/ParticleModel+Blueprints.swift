//
//  ParticleModel+Blueprints.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation
import Blueprints

extension ParticleModel {
    enum MovementColorGenerationStrategy {
        typealias GenerateMovementColor = (ParticleBlueprintModel, MaterialType) -> SIMD4<UInt8>
        
        case random
        case custom(GenerateMovementColor)
        
        var make: GenerateMovementColor {
            switch self {
            case .custom(let closure):
                return closure
            case .random:
                return { _, material in
                    var color = material.color
                    color.z = 0
                    if Bool.random() {
                        color.x = .random(in: 0...255)
                        color.y = 0
                    } else {
                        color.y = .random(in: 0...255)
                        color.x = 0
                    }
                    return color
                }
            }
        }
    }
    
    init(blueprint: ParticleBlueprintModel, material: MaterialType, movementColorGeneration: MovementColorGenerationStrategy = .random) {
        self.x = blueprint.x
        self.y = blueprint.y
        self.material = material
        self.movementColor = movementColorGeneration.make(blueprint, material)
    }
}
