//
//  MaterialModel.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public enum MaterialType: String, Codable, CaseIterable {
    private static let colorDiffThreshold: Float = 0.5
    
    case soil
    case sand
    case rock
    case water
    case oil
    
    private static let b2_waterParticle: UInt32 = 0
    private static let b2_springParticle: UInt32 = 1 << 3
    private static let b2_elasticParticle: UInt32 = 1 << 4
    private static let b2_viscousParticle: UInt32 = 1 << 5
    private static let b2_powderParticle: UInt32 = 1 << 6
    private static let b2_tensileParticle: UInt32 = 1 << 7
    private static let b2_colorMixingParticle: UInt32 = 1 << 8
    private static let b2_reactiveParticle: UInt32 = 1 << 12
    private static let b2_repulsiveParticle: UInt32 = 1 << 13
    
    public var color: SIMD4<UInt8> {
        switch self {
        case .soil: return Colors.Materials.soil
        case .sand: return Colors.Materials.sand
        case .rock: return Colors.Materials.rock
        case .water: return Colors.Materials.water
        case .oil: return Colors.Materials.oil
        }
    }
    
    public var auxColor: SIMD4<UInt8> {
        let mainColor = color
        let modifier: Float = 0.8
        return SIMD4<UInt8>(UInt8(Float(mainColor.x) * modifier),
                            UInt8(Float(mainColor.y) * modifier),
                            UInt8(Float(mainColor.z) * modifier),
                            UInt8(Float(mainColor.w) * modifier))
    }
    
    /// 0 is zero gravity, 1 is planet gravity radius, and so on
    public var gravityScale: CGFloat {
        switch self {
        case .water:
            return 0.7
        default:
            return 1.0
        }
    }
    
    /// velocity threshold for liquid particle to become static
    public var freezeVelocityThreshold: CGFloat {
        switch self {
        case .soil:
            return 2
        case .sand:
            return 1
        case .rock:
            return 10
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
        case .soil:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .sand:
            flags |= Self.b2_powderParticle
        case .rock:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle
        case .oil:
            flags |= Self.b2_waterParticle | Self.b2_viscousParticle
        case .water:
            flags |= Self.b2_waterParticle
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

// Rendering
extension MaterialType {
    public var blurModifier: CGFloat {
        switch self {
        case .soil: return 1
        case .sand: return 0.5
        case .rock: return 0.7
        case .water: return 1
        case .oil: return 1.2
        }
    }
    
    /// Threshold for metaballs alpha texture cropping
    public var cropThreshold: Float {
        switch self {
        case .soil: return 0.5
        case .sand: return 0.5
        case .rock: return 0.6
        case .water: return 0.5
        case .oil: return 0.35
        }
    }
    
    /// scale for alpha radius (when drawing metaballs)
    public var alphaTextureRadiusModifier: Float {
        switch self {
        case .soil: return 1
        case .sand: return 1.3
        case .rock: return 1
        case .water: return 1.2
        case .oil: return 1.2
        }
    }
    
    /// scale for movement texture radius (when drawing metaballs) for smoother/sharper movement pattern
    public var movmentTextureRadiusModifier: Float {
        switch self {
        case .soil: return 1
        case .sand: return 1
        case .rock: return 1
        case .water: return 1
        case .oil: return 1
        }
    }
    
    /// Threshold for movement channels color distribution [0...0.5]
    public var movementTextureThresold: Float {
        switch self {
        case .soil: return 0.25
        case .sand: return 0.25
        case .rock: return 0.25
        case .water: return 0.25
        case .oil: return 0.25
        }
    }
}
