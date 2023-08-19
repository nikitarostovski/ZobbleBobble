//
//  PlanetModel.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation
import Levels

struct PlanetModel {
    /// Rotation speed, degrees per second
    var speed: CGFloat
    
    /// Set of initial material chunks
    var chunks: [ChunkModel]
    
    /// Gravity force will attract particles within gravity field of this radius to the planet center
    var gravityRadius: CGFloat
    
    /// Gravity field force
    var gravitySthrength: CGFloat
    
    /// Particle radius
    let particleRadius: CGFloat
    
    let uniqueMaterials: [MaterialType]
    
    /// Object describing active conditions and restrictions
    var license: LicenseModel
    
    init(speed: CGFloat, chunks: [ChunkModel], license: LicenseModel, gravityRadius: CGFloat, gravitySthrength: CGFloat, particleRadius: CGFloat) {
        self.license = license
        self.speed = speed
        self.chunks = chunks
        self.gravityRadius = gravityRadius
        self.gravitySthrength = gravitySthrength
        self.particleRadius = particleRadius
        
        self.uniqueMaterials = Array(Set(chunks.flatMap { $0.particles.map { $0.material } }))
    }
}