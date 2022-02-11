//
//  BulletNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 22.01.2022.
//

import SpriteKit

final class BulletNode: SKShapeNode, MissleNode {
    var destructionArea: Polygon {
        Polygon.make(radius: 20, vertexCount: 8).map { CGPoint(x: $0.x + position.x, y: $0.y + position.y) }
    }
    
    static func make() -> MissleNode {
        let m = BulletNode(circleOfRadius: 2)
        m.fillColor = .white
        
        let body = SKPhysicsBody(circleOfRadius: 2)
        body.isDynamic = true
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.friction = 100
        body.categoryBitMask = Category.missle.rawValue
        body.collisionBitMask = Category.terrain.rawValue
        body.contactTestBitMask = Category.missle.rawValue//Category.terrain.rawValue
        
        m.physicsBody = body
        return m
    }
    
    func explode() {
        physicsBody = nil
        removeFromParent()
    }
    
    func processHit(with chunk: ChunkNode, terrain: TerrainNode, impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) {
        explode()
        
        DispatchQueue.global(qos: .userInteractive).async {
            terrain.chunks.forEach { chunk in
                guard chunk.state == .stable else { return }
                let newPolygons = chunk.model.globalPolygon.difference(from: self.destructionArea)

                let newChunkModels = newPolygons.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
                let newChunks = newChunkModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .stable) }
                DispatchQueue.main.async {
                    terrain.replace(chunk: chunk, with: newChunks)
                }
            }
        }
    }
}
