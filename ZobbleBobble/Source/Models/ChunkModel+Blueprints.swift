//
//  ChunkModel+Blueprints.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation
import Blueprints

extension ChunkModel {
    enum MaterialChoiceStrategy {
        typealias ChooseMaterial = ([MaterialType]) -> MaterialType
        
        case random
        case custom(ChooseMaterial)
        
        var make: ChooseMaterial {
            switch self {
            case .custom(let closure):
                return closure
            case .random:
                return { possibleMaterials in
                    possibleMaterials.randomElement() ?? .rock
                }
            }
        }
    }
    
    init(blueprint: ChunkBlueprintModel, startImpulse: CGFloat, materialChoice: MaterialChoiceStrategy = .random) {
        var particles = [ParticleModel]()
        for group in blueprint.particleGroups {
            let possibleMaterials = MaterialType.getMaterials(for: group.possibleMaterials)
            let material = materialChoice.make(possibleMaterials)
            for position in group.positions {
                let particle = ParticleModel(blueprint: position, material: material)
                particles.append(particle)
            }
        }
        self.particles = particles
        self.startImpulse = startImpulse
        self.boundingRadius = blueprint.boundingRadius
    }
}
