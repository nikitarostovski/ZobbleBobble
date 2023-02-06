//
//  MaterialModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public enum MaterialType: String, Codable {
    private static let b2_waterParticle: UInt32 = 0
    private static let b2_springParticle: UInt32 = 1 << 3
    private static let b2_elasticParticle: UInt32 = 1 << 4
    private static let b2_viscousParticle: UInt32 = 1 << 5
    private static let b2_powderParticle: UInt32 = 1 << 6
    private static let b2_tensileParticle: UInt32 = 1 << 7
    private static let b2_colorMixingParticle: UInt32 = 1 << 8
    private static let b2_reactiveParticle: UInt32 = 1 << 12
    private static let b2_repulsiveParticle: UInt32 = 1 << 13
    
    case lavaRed
    case lavaYellow
    case bomb
    case coreLight
    case coreDark
    
    public var color: SIMD4<UInt8> {
        switch self {
        case .lavaRed:
            return SIMD4<UInt8>(255, 96, 64, 255)
        case .lavaYellow:
            return SIMD4<UInt8>(220, 185, 10, 255)
        case .bomb:
            return SIMD4<UInt8>(100, 200, 170, 255)
        case .coreLight:
            return SIMD4<UInt8>(200, 200, 200, 255)
        case .coreDark:
            return SIMD4<UInt8>(100, 100, 100, 255)
        }
    }

    public enum ParticleContactBehavior: Int {
        case none = 0
        case becomeLiquid = 1
        case explosive = 2
    }
    
    /// 0 is zero gravity, 1 is planet gravity radius, and so on
    public var gravityScale: CGFloat {
        return 0.5
    }
    
    /// velocity threshold for liquid particle to become static
    public var freezeVelocityThreshold: CGFloat {
        return 2
    }
    
    /// behavior to be taken in case of contact with a static particle
    public var staticContactBehavior: ParticleContactBehavior {
        switch self {
        case .bomb:
            return .explosive
        case .lavaRed, .lavaYellow:
            return .becomeLiquid
        default:
            return .none
        }
    }
    
    /// physical parameters of liquid state
    public var physicsFlags: UInt32 {
        var flags = UInt32(0)
        switch self {
        case .lavaRed, .lavaYellow, .coreLight, .coreDark:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .bomb:
            flags |= Self.b2_waterParticle
        }
                
        return flags
    }
    
    public var explosionRadius: CGFloat {
        switch self {
        case .bomb:
            return 20
        default:
            return -1
        }
    }
}
