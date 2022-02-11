//
//  RocketNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 19.01.2022.
//

import SpriteKit

final class RocketNode: SKShapeNode, MissleNode {
    
    var destructionArea: Polygon {
        Polygon.make(radius: 20, vertexCount: 8).map { CGPoint(x: $0.x + position.x, y: $0.y + position.y) }
    }

    var crackArea: Polygon {
        Polygon.make(radius: 40, vertexCount: 10).map { CGPoint(x: $0.x + position.x, y: $0.y + position.y) }
    }
    
    static func make() -> MissleNode {
        let m = RocketNode(circleOfRadius: 2)
        m.fillColor = .white
        
        let body = SKPhysicsBody(circleOfRadius: 2)
        body.isDynamic = true
        body.affectedByGravity = false
        body.friction = 100
        body.usesPreciseCollisionDetection = true
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
//            terrain.chunks.forEach { chunk in
//                guard chunk.state == .stable else { return }
//                let newPolygons = chunk.model.globalPolygon.difference(from: self.destructionArea)
//
//                let newChunkModels = newPolygons.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
//                let newChunks = newChunkModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .stable) }
//                DispatchQueue.main.async {
//                    terrain.replace(chunk: chunk, with: newChunks)
//                }
//            }
            
//            terrain.chunks.forEach { chunk in
//                guard chunk.state == .stable else { return }
//                guard !chunk.model.globalPolygon.intersection(with: self.crackArea).isEmpty else { return }
//
//                var newPolygons = chunk.model.globalPolygon.split(minDistance: 12)//.destruct(impulse: impulse, normal: normal, contactPoint: contactPoint)
////                newPolygons = newPolygons.filter { $0.area >= Const.chunkMinArea }
//
//                let dynamicPolygons = newPolygons.filter {
//                    !$0.intersection(with: self.crackArea).isEmpty
//                }
//
//                var staticPolygons = [chunk.model.globalPolygon]
//                dynamicPolygons.forEach {
//                    var newStaticPolygons = [Polygon]()
//                    for s in staticPolygons {
//                        newStaticPolygons += s.difference(from: $0)
//                    }
//                    staticPolygons = newStaticPolygons
//                }
//
//                let newStaticModels = staticPolygons.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
//                let newDynamicModels = dynamicPolygons.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
//
//                let newStaticChunks = newStaticModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .stable) }
//                let newDynamicChunks = newDynamicModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .destroying) }
//
//                DispatchQueue.main.async {
//                    terrain.replace(chunk: chunk, with: newStaticChunks + newDynamicChunks)
//
//                    newDynamicChunks.forEach { chunk in
//                        chunk.xScale = 0.8
//                        chunk.yScale = 0.8
//
//                        let imp: CGFloat = 3//impulse * impulse * impulse * impulse
//                        chunk.physicsBody?.applyImpulse(CGVector(dx: normal.dx * imp, dy: normal.dy * imp))
//                    }
//                }
//            }
//        }
        
            
            
            terrain.chunks.forEach { chunk in
                guard chunk.state == .stable else { return }
                guard !chunk.model.globalPolygon.intersection(with: self.crackArea).isEmpty else { return }
                
                var dynamicChunks = chunk.model.globalPolygon.intersection(with: self.crackArea)
                let staticChunks = chunk.model.globalPolygon.difference(from: self.crackArea)
                
                guard dynamicChunks.count > 0 else {
                    return
                }
                
                dynamicChunks = dynamicChunks.flatMap { chunk in
                    return chunk.split(minDistance: 10)
                }
                
                let newStaticModels = staticChunks.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
                let newDynamicModels = dynamicChunks.map { Chunk(globalPolygon: $0, material: chunk.model.material) }
                
                DispatchQueue.main.async {
                    let newStaticChunks = newStaticModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .stable) }
                    let newDynamicChunks = newDynamicModels.map { ChunkNode.make(chunk: $0, terrain: terrain, state: .destroying) }
                    
                    terrain.replace(chunk: chunk, with: newStaticChunks + newDynamicChunks)
                    
                    newDynamicChunks.forEach { chunk in
                        chunk.xScale = 0.8
                        chunk.yScale = 0.8

                        let imp: CGFloat = 3//impulse * impulse * impulse * impulse
                        chunk.physicsBody?.applyImpulse(CGVector(dx: normal.dx * imp, dy: normal.dy * imp))
                    }
                }
            }
        }
    }
}
