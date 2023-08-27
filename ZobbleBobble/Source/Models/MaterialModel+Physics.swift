//
//  MaterialModel+Physics.swift
//  ZobbleBobble
//
//  Created by Rost on 27.08.2023.
//

import Foundation

extension MaterialType {
    private static let b2_waterParticle: UInt32 = 0
    private static let b2_springParticle: UInt32 = 1 << 3
    private static let b2_elasticParticle: UInt32 = 1 << 4
    private static let b2_viscousParticle: UInt32 = 1 << 5
    private static let b2_powderParticle: UInt32 = 1 << 6
    private static let b2_tensileParticle: UInt32 = 1 << 7
    private static let b2_colorMixingParticle: UInt32 = 1 << 8
    private static let b2_staticPressureParticle = 1 << 11
    private static let b2_reactiveParticle: UInt32 = 1 << 12
    private static let b2_repulsiveParticle: UInt32 = 1 << 13
    
    /// 0 is zero gravity, 1 is planet gravity radius, and so on
    public var gravityScale: CGFloat {
        switch self {
        case .dust:
            return 0.5
        case .water, .acid:
            return 0.7
        default:
            return 1.0
        }
    }
    
    /// velocity threshold for liquid particle to become static
    public var freezeVelocityThreshold: CGFloat {
        switch self {
        case .organic, .metal, .dust:
            return 2
        case .sand:
            return 1
        case .rock:
            return 10
        case .magma:
            return 0.5
        default:
            return -1
        }
    }
    
    /// behavior to be taken in case of contact with a static particle
    public var becomesLiquidOnContact: Bool {
//        switch self {
//        case .bomb:
//            return false
//        default:
            return true
//        }
    }
    
    /// physical parameters of liquid state
    public var physicsFlags: UInt32 {
        var flags = UInt32(0)
        switch self {
        case .organic:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .rock:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .metal:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .sand:
            flags |= Self.b2_powderParticle
        case .magma:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .acid:
            flags |= Self.b2_waterParticle | Self.b2_colorMixingParticle
        case .dust:
            flags |= Self.b2_powderParticle
        case .water:
            flags |= Self.b2_waterParticle | Self.b2_colorMixingParticle
        case .oil:
            flags |= Self.b2_waterParticle | Self.b2_viscousParticle
        }
                
        return flags
    }
    
    public var explosionRadius: CGFloat {
//        switch self {
//        case .bomb:
//            return 20
//        default:
            return -1
//        }
    }
}
