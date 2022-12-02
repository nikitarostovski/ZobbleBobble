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
    var terrainNodes = [TerrainNode]()
    
    init(world: World, level: Level) {
        self.world = world
        self.level = level
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateViewport(center: CGPoint, size: CGSize) {
        if level.performUpdateForNewViewport(newCenter: center, newSize: size) {
            updateChunkNodesIfNeeded()
        }
    }
    
    private func updateChunkNodesIfNeeded() {
        let visibleChunks = level.visibleChunks
        let nodesToRemove = terrainNodes.filter { terrainNode in
            if let _ = visibleChunks.first(where: { $0.uuid == terrainNode.chunkUUID }) {
                return false
            }
            return true
        }
        
        let chunksToAdd = visibleChunks.filter { levelChunk in
            if terrainNodes.first(where: { $0.chunkUUID == levelChunk.uuid }) == nil {
                return true
            }
            return false
        }
        
        nodesToRemove.forEach { nodeToRemove in
            nodeToRemove.removeFromParent()
            self.terrainNodes.removeAll(where: { $0.chunkUUID == nodeToRemove.chunkUUID })
        }
        chunksToAdd.forEach { chunkToAdd in
            addChunk(levelChunk: chunkToAdd)
        }
    }
    
    private func addChunk(levelChunk: LevelChunk) {
        let t = TerrainNode(chunkUUID: levelChunk.uuid, polygon: levelChunk.polygon, physicsWorld: world.world)
        addChild(t)
        terrainNodes.append(t)
    }
}

class TerrainNode: RigidBodyNode {
    let chunkUUID: UUID
    
    init(chunkUUID: UUID, polygon: Polygon, physicsWorld: ZPWorld) {
        self.chunkUUID = chunkUUID
        super.init()
        
        let path = CGMutablePath()
        path.addLines(between: polygon)
        path.closeSubpath()
        self.path = path
        
        self.strokeColor = UIColor.white
        self.fillColor = UIColor(red: 155/255, green: 139/255, blue: 118/255, alpha: 0.5)
        
        self.body = ZPRigidBody(polygon: polygon.map { NSValue(cgPoint: $0) },
                                isDynamic: false,
                                position: .zero,
                                density: 1,
                                friction: 0,
                                restitution: 0,
                                at: physicsWorld)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
