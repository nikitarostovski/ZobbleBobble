//
//  LevelNode.swift
//  ZobbleBobble
//
//  Created by Rost on 29.11.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

class LevelNode: SKNode {
    let world: World
    let level: Level
    var liquidNode: LiquidNode
    
    init(world: World, level: Level) {
        self.world = world
        self.level = level
        self.liquidNode = LiquidNode(world: world)
        super.init()
        
        addChild(liquidNode)
        
        let coreNode = CoreNode(radius: 20, world: world)
        addChild(coreNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func spawnComet(at point: CGPoint) {
        let radius = CGFloat.random(in: 10...20)
        
        let cometType = CometType.water//allCases.randomElement()!
        
        switch cometType {
        case .water:
            liquidNode.addLiquid(radius: radius, position: point)
        case .ground:
            let node = SolidNode(radius: radius, position: point, category: CAT_COMET, world: world)
            addChild(node)
        }
    }
    
    func replace(node: RigidBodyNode, with nodes: [RigidBodyNode]) {
        node.removeFromParent()
        
        nodes.forEach {
            addChild($0)
        }
    }
    
    func update() {
        children.forEach {
            if let n = $0 as? RigidBodyNode {
                n.update()
            }
            if let n = $0 as? LiquidNode {
                n.update()
            }
        }
    }
}
