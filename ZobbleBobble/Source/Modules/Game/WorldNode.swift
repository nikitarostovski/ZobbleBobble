//
//  WorldNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.01.2022.
//

import SpriteKit

final class WorldNode: SKNode {
    var core: CoreNode
    var chunks: [ChunkNode]
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Terrain
        terrainNode?.removeFromParent()
        terrainNode = TerrainNode.make(terrain: terrain)
        addChild(terrainNode!)
        
        // Player
        playerNode?.removeFromParent()
        playerNode = PlayerNode.make()
        addChild(playerNode!)
        
        playerNode?.weaponNode = BazookaNode.make()
        
        // Camera
        sceneCamera.removeFromParent()
        addChild(sceneCamera)
        camera = sceneCamera
        
        // Physics
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = contactProcessor
        contactProcessor.terrain = terrainNode
        
        let g = SKFieldNode.radialGravityField()
        g.strength = 120
        node.addChild(g)
    }
}
