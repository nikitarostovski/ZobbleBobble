//
//  CoreNode.swift
//  ZobbleBobble
//
//  Created by Rost on 15.12.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

class CoreNode: RigidBodyNode {
    var size: CGFloat
    init(radius: CGFloat, position: CGPoint = .zero, world: World) {
        self.size = 2 * radius
        super.init()
        self.world = world
        
        let polygon = Polygon.make(radius: radius, position: .zero, vertexCount: 6)
        let path = CGMutablePath()
        path.addLines(between: polygon)
        path.closeSubpath()
        
        self.path = path
        self.position = position
        
        self.strokeColor = UIColor.clear
        self.fillColor = UIColor(red: 255/255, green: 139/255, blue: 118/255, alpha: 1)
        
        let values = polygon.map { NSValue(cgPoint: $0) }
        
        self.polygon = polygon
        self.body = ZPRigidBody(polygon: values,
                                isDynamic: false,
                                position: position,
                                density: 1,
                                friction: 1,
                                restitution: 0,
                                category: CAT_CORE,
                                at: world.world)
        
        self.body?.onContact = { _ in }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
