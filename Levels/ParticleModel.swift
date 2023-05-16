//
//  ParticleModel.swift
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
//

import Foundation

public struct ParticleModel: Codable {
    public let x: CGFloat
    public let y: CGFloat
    public let material: MaterialType
    
    public var position: CGPoint { CGPoint(x: x, y: y) }
    
    public init(position: CGPoint, material: MaterialType) {
        self.x = position.x
        self.y = position.y
        self.material = material
    }
}
