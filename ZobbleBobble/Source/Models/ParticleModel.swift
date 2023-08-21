//
//  ParticleModel.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public struct ParticleModel: Codable {
    public let x: CGFloat
    public let y: CGFloat
    public let material: MaterialType
    public let movementColor: SIMD4<UInt8>
    
    public var position: CGPoint { CGPoint(x: x, y: y) }
}
