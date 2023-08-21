//
//  PlanetModel.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct LimitationsModel: Codable {
    struct EmptyValue: Codable { }
    struct Limit<T: Codable>: Codable {
        let value: T
        let fine: Int
    }
    
    struct SectorModel: Codable {
        /// Degrees
        let startAngle: Float
        /// Degrees
        let sectorSize: Float
    }
    
    let radiusLimit: Limit<Float>
    let sectorLimit: Limit<[SectorModel]>
    let materialWhitelist: Limit<[MaterialType]>
    let totalParticleAmountLimit: Limit<Int>
    let outerSpaceLimit: Limit<EmptyValue>
}

class PlanetModel: Codable {
    /// Amount of credits to unlock this planet
    let price: UInt64
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
    /// Object describing conditions and restrictions
    var limits: LimitationsModel?
    
    enum CodingKeys: String, CodingKey {
        case price
        case speed
        case chunks
        case gravityRadius
        case gravityStrength
        case particleRadius
        case limits
    }
    
    init(price: UInt64, speed: CGFloat, chunks: [ChunkModel], limits: LimitationsModel?, gravityRadius: CGFloat, gravityStrength: CGFloat, particleRadius: CGFloat) {
        self.price = price
        self.speed = speed
        self.chunks = chunks
        self.gravityRadius = gravityRadius
        self.gravityStrength = gravityStrength
        self.particleRadius = particleRadius
        self.limits = limits
        
        self.uniqueMaterials = Array(Set(chunks.flatMap { $0.particles.map { $0.material } }))
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.price = try container.decode(UInt64.self, forKey: .price)
        self.speed = try container.decode(CGFloat.self, forKey: .speed)
        self.chunks = try container.decode([ChunkModel].self, forKey: .chunks)
        self.gravityRadius = try container.decode(CGFloat.self, forKey: .gravityRadius)
        self.gravityStrength = try container.decode(CGFloat.self, forKey: .gravityStrength)
        self.particleRadius = try container.decode(CGFloat.self, forKey: .particleRadius)
        self.limits = try container.decode(LimitationsModel.self, forKey: .limits)
        
        self.uniqueMaterials = Array(Set(chunks.flatMap { $0.particles.map { $0.material } }))
    }
}
