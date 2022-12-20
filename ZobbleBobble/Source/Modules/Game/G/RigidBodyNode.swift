//
//  RigidBodyNode.swift
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

import Foundation
import SpriteKit
import ZobblePhysics
import ZobbleCore

class RigidBodyNode: SKShapeNode {
    var world: World?
    var body: ZPRigidBody?
    var polygon: Polygon?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        guard let body = body else { return }
        self.position = body.position
        self.zRotation = body.angle
    }
    
    func crack(at point: CGPoint) {
        guard let polygon = polygon, let world = world else { return }
        let newPolygons = polygon.split(minDistance: 10)
        
        let nodes = newPolygons
            .filter { 3...8 ~= $0.count }
            .map {
                SolidNode(polygon: $0, position: self.position, category: CAT_VOID, world: world)
            }
        world.replace(node: self, with: nodes)
    }
    
    func destroy() {
        
    }
}
