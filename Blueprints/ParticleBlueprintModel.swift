//
//  ParticleBlueprintModel.swift
//  Blueprints
//
//  Created by Никита Ростовский on 29.09.2023.
//

import Foundation

/// Blueprint is a simplified particle description, not full. Used to generate an actual particle procedurally
public struct ParticleBlueprintModel: Codable {
    public let x: CGFloat
    public let y: CGFloat
    
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}
