//
//  ChunkBlueprintModel.swift
//  Blueprints
//
//  Created by Rost on 21.08.2023.
//

import Foundation

/// Blueprint is a simplified chunk description, not full. Used to generate an actual chunk procedurally
public struct ChunkBlueprintModel: Codable {
    public struct FuzzyParticleGroup: Codable {
        public let positions: [ParticleBlueprintModel]
        public let possibleMaterialCategories: [MaterialCategory]
        
        public init(positions: [ParticleBlueprintModel], possibleMaterialCategories: [MaterialCategory]) {
            self.positions = positions
            self.possibleMaterialCategories = possibleMaterialCategories
        }
    }
    
    public let core: CoreBlueprintModel?
    public let particleGroups: [FuzzyParticleGroup]
    public let boundingRadius: CGFloat
    
    public init(core: CoreBlueprintModel?, particleGroups: [FuzzyParticleGroup], boundingRadius: CGFloat) {
        self.core = core
        self.particleGroups = particleGroups
        self.boundingRadius = boundingRadius
    }
}
