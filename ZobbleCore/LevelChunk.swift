//
//  LevelChunk.swift
//  ZobbleCore
//
//  Created by Rost on 30.11.2022.
//

import Foundation

public struct LevelChunk {
    public let uuid = UUID()
    public let polygon: Polygon
    public let bounds: CGRect
    public let material: Material
    
    public let startHeight: CGFloat
    public let exitHeight: CGFloat
    
    public var maxHeight: CGFloat { max(startHeight, exitHeight) }
    public var minHeight: CGFloat { min(startHeight, exitHeight) }
    
    public init(polygon: Polygon, material: Material, startHeight: CGFloat, exitHeight: CGFloat) {
        self.polygon = polygon
        self.material = material
        self.startHeight = startHeight
        self.exitHeight = exitHeight
        self.bounds = polygon.bounds
    }
}
