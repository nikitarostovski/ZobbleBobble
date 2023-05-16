//
//  MaterialModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public enum MaterialType: String, Codable, CaseIterable {
    private static let colorDiffThreshold: Float = 0.5
    
    case lavaRed
    case lavaYellow
    case bomb
    case coreLight
    case coreDark
    case water
    
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
        case .lavaRed:
            return SIMD4<UInt8>(255, 96, 64, 0)
        case .lavaYellow:
            return SIMD4<UInt8>(220, 185, 10, 1)
        case .bomb:
            return SIMD4<UInt8>(100, 200, 170, 2)
        case .coreLight:
            return SIMD4<UInt8>(200, 200, 200, 3)
        case .coreDark:
            return SIMD4<UInt8>(100, 100, 100, 4)
        case .water:
            return SIMD4<UInt8>(64, 128, 255, 5)
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
        case .water:
            return -1
        case .lavaRed:
            return 5
        default:
            return 10
        }
    }
    
    /// behavior to be taken in case of contact with a static particle
    public var becomesLiquidOnContact: Bool {
        switch self {
        case .bomb:
            return false
        default:
            return true
        }
    }
    
    /// physical parameters of liquid state
    public var physicsFlags: UInt32 {
        var flags = UInt32(0)
        switch self {
        case .lavaRed, .lavaYellow, .coreLight, .coreDark:
            flags |= Self.b2_viscousParticle | Self.b2_tensileParticle// | Self.b2_colorMixingParticle
        case .bomb:
            flags |= Self.b2_waterParticle
        case .water:
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
