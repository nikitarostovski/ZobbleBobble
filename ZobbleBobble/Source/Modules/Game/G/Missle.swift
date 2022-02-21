//
//  Missle.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 08.02.2022.
//

import SpriteKit

enum MissleType {
    case bullet
    case rocket
    case nuke
}

class Missle: SKShapeNode {
    let radius: CGFloat = 4
    
    let world: World
    let type: MissleType
    
    var destructionArea: Polygon {
        Polygon.make(radius: 20, vertexCount: 8).map { CGPoint(x: $0.x + position.x, y: $0.y + position.y) }
    }
    
    init(world: World, type: MissleType, position: CGPoint) {
        self.world = world
        self.type = type
        super.init()
        
        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius), transform: nil)
    
        self.path = path
        self.position = position
        self.fillColor = .yellow
        self.strokeColor = .clear
        
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = true
        body.mass = 0.05
        
        body.categoryBitMask = Category.missle.rawValue
        body.collisionBitMask = Category.terrain.rawValue | Category.core.rawValue
        body.contactTestBitMask = Category.terrain.rawValue
        
        
        self.physicsBody = body
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func explode() {
        physicsBody = nil
        removeFromParent()
    }
    
    func processCollision(at contactPoint: CGPoint, impulse: CGFloat) {
        explode()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            let processing: (CGPoint, CGFloat, ([Chunk], [Chunk]) -> Void) -> Void
            switch self.type {
            case .bullet:
                processing = self.processCollisionDestruct(at:impulse:completion:)
            case .rocket, .nuke:
                processing = self.processCollisionExplode(at:impulse:completion:)
            }
            
            processing(contactPoint, impulse, { (chunksToRemove, chunksToAdd) in
                DispatchQueue.main.async {
                    self.world.replace(chunks: chunksToRemove, with: chunksToAdd)
                }
            })
        }
    }
    
    private func processCollisionDestruct(at contactPoint: CGPoint, impulse: CGFloat, completion: ([Chunk], [Chunk]) -> Void) {
        let destructionArea = self.destructionArea
        var chunksToRemove = [Chunk]()
        var chunksToAdd = [Chunk]()
        
        let affectedChunks = world.chunks.filter { chunk in
            let intersection = chunk.globalPolygon.intersection(with: destructionArea)
            return !intersection.isEmpty
        }
        
        affectedChunks.forEach { chunk in
            guard !chunksToRemove.contains(chunk) else { return }
            let newPolygons = chunk.globalPolygon.difference(from: destructionArea)

            let newChunks = newPolygons.map { polygon in
                return Chunk(world: self.world, globalPolygon: polygon, material: chunk.material, type: .terrain)
            }
            chunksToRemove.append(chunk)
            chunksToAdd.append(contentsOf: newChunks)
        }
        
        completion(chunksToRemove, chunksToAdd)
    }
    
    private func processCollisionExplode(at contactPoint: CGPoint, impulse: CGFloat, completion: ([Chunk], [Chunk]) -> Void) {
        let destructionArea = self.destructionArea
        var chunksToRemove = [Chunk]()
        var chunksToAdd = [Chunk]()
        
        world.chunks.forEach { chunk in
            guard chunk.type == .terrain else { return }
            guard !chunksToRemove.contains(chunk) else { return }
            
            let dist = chunk.material.minSplitDistance
            
            var dynamicChunks = chunk.globalPolygon.intersection(with: destructionArea)
            let staticChunks = chunk.globalPolygon.difference(from: destructionArea)
            
            guard dynamicChunks.count > 0 else {
                return
            }
            
            dynamicChunks = dynamicChunks.flatMap { chunk in
                return chunk.split(minDistance: dist)
            }
            
            let newStaticChunks = staticChunks.map { polygon in
                Chunk(world: self.world, globalPolygon: polygon, material: chunk.material, type: .terrain)
            }
            
            let newDynamicChunks: [Chunk] = dynamicChunks.map { polygon in
                let c = Chunk(world: self.world, globalPolygon: polygon, material: chunk.material, type: .fragment)
                if let oldBody = chunk.physicsBody {
                    c.physicsBody?.angularVelocity = oldBody.angularVelocity
                    c.physicsBody?.velocity = oldBody.velocity
                }
                return c
            }
            
            chunksToRemove.append(chunk)
            chunksToAdd.append(contentsOf: newStaticChunks)
            chunksToAdd.append(contentsOf: newDynamicChunks)
        }
        
        completion(chunksToRemove, chunksToAdd)
    }
}
