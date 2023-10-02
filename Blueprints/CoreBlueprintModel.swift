//
//  CoreBlueprintModel.swift
//  Blueprints
//
//  Created by Никита Ростовский on 29.09.2023.
//

import Foundation

/// Blueprint is a simplified circle object description, not full. Used to generate planet's core
public struct CoreBlueprintModel: Codable {
    public let x: CGFloat
    public let y: CGFloat
    public let radius: CGFloat
    
    public init(x: CGFloat, y: CGFloat, radius: CGFloat) {
        self.x = x
        self.y = y
        self.radius = radius
    }
}
