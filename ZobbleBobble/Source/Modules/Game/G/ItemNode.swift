//
//  ItemNode.swift
//  ZobbleBobble
//
//  Created by Rost on 18.11.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

class ItemNode: RigidBodyNode {
    var size: CGFloat
    init(radius: CGFloat, position: CGPoint = .zero, physicsWorld: ZPWorld) {
        self.size = 2 * radius
        super.init()
        
        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius), transform: nil)
        self.path = path
        
        self.strokeColor = UIColor.clear
        self.fillColor = UIColor(red: 155/255, green: 139/255, blue: 118/255, alpha: 1)
        
        self.body = ZPRigidBody(radius: Float(radius),
                                isDynamic: true,
                                position: position,
                                density: 1,
                                friction: 1,
                                restitution: 0,
                                at: physicsWorld)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
