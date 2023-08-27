//
//  MaterialModel.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public enum MaterialType: String, Codable, CaseIterable {
    case organic
    case rock
    case metal
    case magma
    case sand
    case water
    case acid
    case dust
    case oil
    
    public var color: SIMD4<UInt8> {
        switch self {
        case .organic: return Colors.Materials.organic
        case .rock: return Colors.Materials.rock
        case .metal: return Colors.Materials.metal
        case .magma: return Colors.Materials.magma
        case .sand: return Colors.Materials.sand
        case .water: return Colors.Materials.water
        case .acid: return Colors.Materials.acid
        case .dust: return Colors.Materials.dust
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
}
