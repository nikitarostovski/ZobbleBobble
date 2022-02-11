//
//  TerrainNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit

final class TerrainNode: SKNode {
    var model: Terrain?
    
    var chunks: [ChunkNode]!
    var core: CoreNode?
    
    static func make(terrain: Terrain) -> TerrainNode {
        let node = TerrainNode()
        node.model = terrain
        node.chunks = terrain.chunks.map { ChunkNode.make(chunk: $0, terrain: node, state: .stable) }
        if let core = terrain.core {
            let coreNode = CoreNode.make(chunk: core, terrain: node)
            node.core = coreNode
            node.addChild(coreNode)
        }
        
        node.chunks.forEach { node.addChild($0) }
        
        let g = SKFieldNode.radialGravityField()
        g.strength = 12
        node.addChild(g)
        
        return node
    }
    
    func replace(chunk: ChunkNode, with newChunks: [ChunkNode]) {
        chunk.removeFromParent()
        chunks.removeAll(where: { $0 === chunk })
        
        chunks.append(contentsOf: newChunks)
        newChunks.forEach { self.addChild($0) }
    }
}
