//
//  MaterialModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
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
    
    public static func parseColor(_ color: SIMD4<UInt8>) -> MaterialType? {
        guard color.w > 0 else { return nil }
        
        let total: Float = sqrt(255 * 255 * 3)
        
        let materialsDiff: [(Float, MaterialType)] = MaterialType.allCases.compactMap {
            let rdiff = Int($0.color.x) - Int(color.x)
            let gdiff = Int($0.color.y) - Int(color.y)
            let bdiff = Int($0.color.z) - Int(color.z)
            
            
            let d = sqrt(Float(rdiff * rdiff + gdiff * gdiff + bdiff * bdiff))
            let p = d / total
            
            guard p < Self.colorDiffThreshold else { return nil }
            return (p, $0)
        }
        
        let sorted = materialsDiff.sorted(by: { $0.0 < $1.0 })
        
        let closest = sorted.first?.1
        return closest
    }
}

// Rendering
extension MaterialType {
    public var blurModifier: CGFloat {
        switch self {
        case .soil: return 1
        case .sand: return 0
        case .rock: return 1
        case .water: return 1
        case .oil: return 1
        }
    }
    
    public var cropThreshold: Float {
        switch self {
        case .soil: return 0.5
        case .sand: return 0.4
        case .rock: return 0.5
        case .water: return 0.5
        case .oil: return 0.5
        }
    }
}
