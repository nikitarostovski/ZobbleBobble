//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit

final class World: SKNode {
    var coreAnchor: SKNode!
    var core: Core!
    var chunks = [Chunk]()
    var player: Player!
    
    var cameraCenter: CGPoint {
        CGPoint(
            x: player.position.x,
            y: player.position.y / 2
        )
    }
    
    var cameraDistance: CGSize {
        CGSize(
            width: 100,
            height: player.position.distance(to: .zero)
        )
    }
    
    let groundMaterials: [MaterialType] = [
        .rock,
        .sand
    ]
    
    override init() {
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        generate()
        
        let g = SKFieldNode.radialGravityField()
        g.position = core.position
        
        g.strength = 0.05
        g.falloff = 0.5
        g.region = SKRegion(radius: 100)
    
        addChild(g)
        
        self.player = Player(world: self, position: CGPoint(x: 0, y: -250))
        addChild(player)
        player.weapon = Weapon(world: self, type: .gun)
    }
    
    func cleanUp() {
        let eliminated = chunks.filter { $0.physicsBody == nil }
        removeChunks(eliminated)
        
        let outOfBounds = chunks.filter { chunk in
            let a = 1 - (chunk.position.distance(to: .zero) / Const.chunkRemoveRadius)
            return a <= 0
        }
        removeChunks(outOfBounds)
    }
    
    func replace(chunks: [Chunk], with newChunks: [Chunk]) {
        removeChunks(chunks)
        addChunks(newChunks)
    }
    
    func removeChunks(_ oldChunks: [Chunk]) {
        oldChunks.forEach { chunk in
            self.removeNode(chunk)
        }
    }
    
    func addChunks(_ newChunks: [Chunk]) {
        for chunk in newChunks {
            addChild(chunk)
            if let world = scene?.physicsWorld {
                switch chunk.type {
                case .terrain:
                    chunk.link(with: core, at: world)
                case .fragment:
                    let chunkPos = chunk.position
                    let corePos = core.position
                    let d = (chunk.physicsBody?.mass ?? 1)//chunkPos.distance(to: corePos)
                    print(d)
                    let n = CGVector(dx: corePos.y - chunkPos.y, dy: chunkPos.x - corePos.x)
                    let force = CGVector(dx: n.dx * d, dy: n.dy * d)
                    chunk.physicsBody?.applyForce(force, at: .zero)
                }
            }
            chunks.append(chunk)
        }
    }
}

// MARK: - Chunks

extension World {
    
}

// MARK: - Core

extension World {
    private func setupCoreAnchor(at position: CGPoint) {
        if let coreAnchor = self.coreAnchor {
            removeNode(coreAnchor)
            self.coreAnchor = nil
        }
        
        let anchorNode = SKNode()
        anchorNode.position = position
        let anchorBody = SKPhysicsBody(circleOfRadius: 1)
        anchorBody.isDynamic = false
        anchorNode.physicsBody = anchorBody
        addChild(anchorNode)
        self.coreAnchor = anchorNode
    }
    
    private func setupCore() {
        if let core = self.core {
            removeNode(core)
            self.core = nil
        }
        
        let corePolygon = Polygon.make(radius: Const.coreRadius, vertexCount: 6)
        let core = Core(world: self, globalPolygon: corePolygon)
        addChild(core)
        self.core = core
        
        if let coreAnchor = coreAnchor, let bodyA = coreAnchor.physicsBody, let bodyB = core.physicsBody {
            let j = SKPhysicsJointPin.joint(withBodyA: bodyA, bodyB: bodyB, anchor: coreAnchor.position)
            j.shouldEnableLimits = false
            scene?.physicsWorld.add(j)
        }
    }
}

// MARK: - Node utils

extension World {
    private func removeNode(_ node: SKNode) {
        (node as? SKShapeNode)?.fillColor = .red
        if let p = node.physicsBody, let world = scene?.physicsWorld {
            p.joints.forEach { j in
                world.remove(j)
            }
        }
        node.removeFromParent()
        self.chunks.removeAll(where: { $0 === node })
    }
}

// MARK: - Generation

extension World {
    private func generate() {
        removeChunks(chunks)
        
        setupCoreAnchor(at: .zero)
        setupCore()
        
        
        let boundsPolygon = Polygon.make(radius: Const.planetRadius, vertexCount: 12)
        let boundsPolygons = boundsPolygon.split(minDistance: 40)
        let chunkPolygons = boundsPolygons.getDifference(from: [core.globalPolygon])
        let groundChunks: [Chunk] = chunkPolygons.map { polygon in
            let type = groundMaterials.randomElement()!
            let material = Material(type: type)
            let chunk = Chunk(world: self, globalPolygon: polygon, material: material, type: .terrain)
            return chunk
        }
        
        for chunk in groundChunks {
            addChild(chunk)
            if chunk.type == .terrain || chunk.type == .fragment, let world = scene?.physicsWorld {
                chunk.link(with: core, at: world)
            }
            chunks.append(chunk)
        }
        
        
        let rotateAction = SKAction.rotate(byAngle: 2 * .pi, duration: 5)
        let repeatAction = SKAction.repeatForever(rotateAction)
        core.run(repeatAction)
    }
}
