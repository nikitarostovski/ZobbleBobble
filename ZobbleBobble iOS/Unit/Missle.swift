//
//  Missle.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 15.02.2021.
//

import SpriteKit

class Missle: SKShapeNode {
    
    static func make(at position: CGPoint) -> Missle {
        let node = Missle(circleOfRadius: 2)
        node.fillColor = .yellow
        node.position = position
        node.setupPhysics(radius: 2)
        return node
    }
    
    private func setupPhysics(radius: CGFloat) {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.friction = 100
        
        body.categoryBitMask = Category.missle.rawValue
        body.collisionBitMask = Category.wall.rawValue
        
        physicsBody = body
    }
}
