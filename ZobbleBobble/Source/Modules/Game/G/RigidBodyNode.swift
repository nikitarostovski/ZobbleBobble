//
//  RigidBodyNode.swift
//  ZobbleBobble
//
//  Created by Rost on 19.11.2022.
//

import Foundation
import SpriteKit
import ZobblePhysics

class RigidBodyNode: SKShapeNode {
    var body: ZPRigidBody?
    
    override init() {
        super.init()
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .default)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func update(displayLink: CADisplayLink) {
        guard let body = body else { return }
        
        self.position = body.position
        self.zRotation = body.angle
    }
}
