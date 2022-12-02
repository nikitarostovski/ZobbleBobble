//
//  PlayerNode.swift
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

import SpriteKit
import ZobblePhysics

final class PlayerNode: RigidBodyNode {
    private let radius: CGFloat = 10
    
    let world: World
    
    init(world: World, position: CGPoint) {
        self.world = world
        super.init()
        
        let rect = CGRect(x: position.x - radius, y: position.y - radius, width: 2 * radius, height: 2 * radius)
        
        let path = CGMutablePath()
        path.addRect(rect)
        path.closeSubpath()
        self.path = path
        
        self.strokeColor = UIColor.green
        self.fillColor = UIColor.blue
        
        let points: [CGPoint] = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]
        self.body = ZPRigidBody(polygon: points.map { NSValue(cgPoint: $0) },
                                isDynamic: true,
                                position: .zero,
                                density: 1,
                                friction: 1,
                                restitution: 1,
                                at: world.world)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
