//
//  Wall.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Wall: SKShapeNode {
    
    static func make(from polygon: inout Polygon) -> Wall {
        let node = Wall(points: &polygon, count: polygon.count)
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
        
    }
}
