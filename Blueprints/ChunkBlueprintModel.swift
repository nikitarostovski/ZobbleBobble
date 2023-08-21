//
//  ChunkBlueprintModel.swift
//  Blueprints
//
//  Created by Rost on 21.08.2023.
//

import Foundation

/// Blueprint is a simplified particle description, not full. Used to generate an actual particle procedurally
public struct ParticleBlueprintModel: Codable {
    public let x: CGFloat
    public let y: CGFloat
    
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

/// Blueprint is a simplified chunk description, not full. Used to generate an actual chunk procedurally
public struct ChunkBlueprintModel: Codable {
    public struct FuzzyParticleGroup: Codable {
        public let positions: [ParticleBlueprintModel]
        public let possibleMaterials: [MaterialCategory]
        
        public init(positions: [ParticleBlueprintModel], possibleMaterials: [MaterialCategory]) {
            self.positions = positions
            self.possibleMaterials = possibleMaterials
        }
    }
    
    public let particleGroups: [FuzzyParticleGroup]
    public let boundingRadius: CGFloat
    
    public init(particleGroups: [FuzzyParticleGroup], boundingRadius: CGFloat) {
        self.particleGroups = particleGroups
        self.boundingRadius = boundingRadius
    }
}
