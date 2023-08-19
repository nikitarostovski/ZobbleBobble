//
//  PlanetModel.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation
import Levels

struct PlanetModel: Codable {
    /// Rotation speed, degrees per second
    var speed: CGFloat
    
    /// Set of initial material chunks
    var chunks: [ChunkModel]
    
    /// Gravity force will attract particles within gravity field of this radius to the planet center
    var gravityRadius: CGFloat
    
    /// Gravity field force
    var gravityStrength: CGFloat
    
    /// Particle radius
    let particleRadius: CGFloat
    
    let uniqueMaterials: [MaterialType]
    
    /// Object describing active conditions and restrictions
    var license: LicenseModel
    
    enum CodingKeys: String, CodingKey {
        case speed
        case chunks
        case gravityRadius
        case gravityStrength
        case particleRadius
        case license
    }
    
    init(speed: CGFloat, chunks: [ChunkModel], license: LicenseModel, gravityRadius: CGFloat, gravityStrength: CGFloat, particleRadius: CGFloat) {
        self.license = license
        self.speed = speed
        self.chunks = chunks
        self.gravityRadius = gravityRadius
        self.gravityStrength = gravityStrength
        self.particleRadius = particleRadius
        
        self.uniqueMaterials = Array(Set(chunks.flatMap { $0.particles.map { $0.material } }))
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.speed = try container.decode(CGFloat.self, forKey: .speed)
        self.chunks = try container.decode([ChunkModel].self, forKey: .chunks)
        self.gravityRadius = try container.decode(CGFloat.self, forKey: .gravityRadius)
        self.gravityStrength = try container.decode(CGFloat.self, forKey: .gravityStrength)
        self.particleRadius = try container.decode(CGFloat.self, forKey: .particleRadius)
        self.license = try container.decode(LicenseModel.self, forKey: .license)
        
        self.uniqueMaterials = Array(Set(chunks.flatMap { $0.particles.map { $0.material } }))
    }
}

extension PlanetModel {
    init(level: LevelModel, particleRadius: CGFloat) {
        let license = LicenseModel(price: 125,
                                   radiusLimit: .init(value: Float(level.gravityRadius) * 0.5, fine: 1),
                                   sectorLimit: .init(value: [.init(startAngle: 0, sectorSize: 10)], fine: 2),
                                   materialWhitelist: .init(value: [.soil, .rock], fine: 4),
                                   totalParticleAmountLimit: .init(value: 2000, fine: 1),
                                   outerSpaceLimit: .init(value: .init(), fine: 1))

        self.init(speed: level.rotationPerSecond,
                  chunks: level.initialChunks,
                  license: license,
                  gravityRadius: level.gravityRadius,
                  gravityStrength: 1,
                  particleRadius: particleRadius)
    }
}
