//
//  Chunk.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 25.12.2021.
//

import UIKit

final class Chunk {
    var position: CGPoint
    var rotation: CGFloat = 0
    var polygon: [CGPoint]
    
    var material: Material
    
    var globalPolygon: [CGPoint] {
        polygon.map { CGPoint(x: $0.x + position.x, y: $0.y + position.y).rotate(around: position, by: rotation) }
    }
    
    init(position: CGPoint, polygon: [CGPoint], material: Material) {
        self.position = position
        self.polygon = polygon
        self.material = material
    }
    
    init(globalPolygon: [CGPoint], material: Material) {
        self.position = globalPolygon.centroid() ?? .zero
        self.polygon = []
        self.material = material
        
        self.polygon = globalPolygon.map { CGPoint(x: $0.x - position.x, y: $0.y - position.y) }
    }
    
    func applyTransform(position: CGPoint, rotation: CGFloat) {
        self.position = position
        self.rotation = rotation
    }
}
