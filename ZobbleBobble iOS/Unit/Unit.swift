//
//  Unit.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Unit: SKShapeNode {
    
    static func make(at position: CGPoint) -> Unit {
        let node = Unit(circleOfRadius: 10)
        node.fillColor = .red
        node.position = position
        node.setupPhysics(radius: 10)
        return node
    }
    
    func fire() {
        let missleCount = 25
        for i in 0 ..< missleCount {
            let angleDegrees = CGFloat(i) / CGFloat(missleCount) * 360
            let angleRadians = angleDegrees * .pi / 180
            let force: CGFloat = 0.1
            
            let impulse = CGVector(dx: force * cos(angleRadians),
                                   dy: force * sin(angleRadians))
            
            let missle = Missle.make(at: position)
            parent?.addChild(missle)
            missle.physicsBody?.applyImpulse(impulse)
        }
    }
    
    private func setupPhysics(radius: CGFloat) {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = false
        body.friction = 100
        
        body.categoryBitMask = Category.unit.rawValue
        body.collisionBitMask = Category.wall.rawValue | Category.missle.rawValue
        
        physicsBody = body
    }
}
