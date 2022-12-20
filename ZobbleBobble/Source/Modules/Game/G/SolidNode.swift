//
//  SolidNode.swift
//  ZobbleBobble
//
//  Created by Rost on 16.12.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

class SolidNode: RigidBodyNode {
    convenience init(radius: CGFloat, position: CGPoint, category: Int32, world: World) {
        let polygon = Polygon.make(radius: radius, position: .zero, vertexCount: 6)
        self.init(polygon: polygon, position: position, category: category, world: world)
    }
    
    required init(polygon: Polygon, position: CGPoint, category: Int32, world: World) {
        super.init()
        self.world = world
        
        let path = CGMutablePath()
        path.addLines(between: polygon)
        path.closeSubpath()
        
        self.path = path
        self.position = position
        
        self.strokeColor = UIColor.clear
        self.fillColor = UIColor(red: 155/255, green: 139/255, blue: 118/255, alpha: 1)
        
        let values = polygon.map { NSValue(cgPoint: $0) }
        
        self.polygon = polygon
        self.body = ZPRigidBody(polygon: values,
                                isDynamic: true,
                                position: position,
                                density: 1,
                                friction: 1,
                                restitution: 0,
                                category: category,
                                at: world.world)
        
        self.body?.onContact = { [weak self] body in
            guard let self = self, var pos = self.body?.position else { return }
            self.body?.destroy()
            self.crack(at: pos)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
