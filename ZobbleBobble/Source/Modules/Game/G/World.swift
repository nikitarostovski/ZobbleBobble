//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

final class World: SKNode {
    let particleRadius: CGFloat = 2
    
    var world: ZPWorld
    
    private var levelNode: LevelNode!
    
    var worldSize: CGSize { UIScreen.main.bounds.size }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level, camera: SKCameraNode) {
        self.world = ZPWorld(gravity: CGPoint(x: 0, y: 0), particleRadius: particleRadius)
        super.init()
        
        levelNode = LevelNode(world: self, level: level)
        addChild(levelNode)
        addChild(camera)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .default)
    }
    
    @objc
    private func update(displayLink: CADisplayLink) {
        autoreleasepool {
            self.world.worldStep(displayLink.duration, velocityIterations: 6, positionIterations: 2)
            self.levelNode.update()
        }
    }
    
    func onTouch(position: CGPoint) {
        guard var pos = scene?.camera?.convert(position, to: levelNode) else { return }
        pos.x -= worldSize.width
        pos.y *= -1
        
        pos.y += worldSize.height / 2
        pos.x += worldSize.width / 2
        levelNode.spawnComet(at: pos)
    }
    
    func replace(node: RigidBodyNode, with nodes: [RigidBodyNode]) {
        levelNode.replace(node: node, with: nodes)
    }
}
