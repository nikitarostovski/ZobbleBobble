//
//  Wall.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Wall: SKShapeNode {
    
    private var polygon: Polygon?
    
    weak var terrain: Terrain?
    
    static func make(from polygon: inout Polygon) -> Wall {
        let node = Wall(points: &polygon, count: polygon.count)
        node.polygon = polygon
        node.fillColor = UIColor.blue.withAlphaComponent(0.2)
//        let node = Wall(splinePoints: &polygon, count: polygon.count)
        node.setupPhysics(points: polygon)
        return node
    }
    
    private func setupPhysics(points: [CGPoint]) {
        guard points.count > 2 else { return }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = false
        body.friction = 100
        
        body.categoryBitMask = Category.wall.rawValue
        body.collisionBitMask = Category.unit.rawValue
        body.contactTestBitMask = Category.missle.rawValue
        
        physicsBody = body
    }
    
    public func explode(impulse: CGVector) {
        guard let terrain = terrain, let polygon = polygon else { return }
        let newPolygons = [Array(polygon.prefix(3)), Array(polygon.suffix(3))]
        
        let walls = newPolygons.map { p -> Wall in
            var polygon = p
            let wall = Self.make(from: &polygon)
            wall.physicsBody?.isDynamic = true
            return wall
        }
        
        terrain.replace(wall: self, with: walls)
    }
    
    public func destroy() {
        physicsBody = nil
        removeFromParent()
    }
}
