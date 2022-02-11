//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit

final class World: SKNode {
    var core: Chunk!
    var chunks = [Chunk]()
    
    var allChunks: [Chunk] {
        chunks + [core]
    }
    
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
        
//        let g = SKFieldNode.radialGravityField()
//        g.position = core.position
//        g.strength = 1
//        addChild(g)
        
        self.player = Player(world: self, position: CGPoint(x: 0, y: -250))
        addChild(player)
        player.weapon = Weapon(world: self, type: .gun)
    }
    
    func replace(chunks: [Chunk], with newChunks: [Chunk]) {
        removeChunks(chunks)
        addChunks(newChunks)
    }
    
    func removeChunks(_ oldChunks: [Chunk]) {
        oldChunks.forEach { chunk in
            chunk.removeFromParent()
            self.chunks.removeAll(where: { $0 === chunk })
        }
    }
    
    func addChunks(_ newChunks: [Chunk]) {
        chunks.append(contentsOf: newChunks)
        newChunks.forEach {
            addChild($0)
            if $0.type == .terrain, let world = scene?.physicsWorld {
                $0.link(with: core, at: world)
            }
//            rotateChunk($0)
        }
    }
    
    private func rotateChunk(_ chunk: Chunk) {
        guard let physicsBody = chunk.physicsBody, let world = scene?.physicsWorld else { return }
        
        let an = SKNode()
        an.position = chunk.position
        let a = SKPhysicsBody(circleOfRadius: 1)
        a.isDynamic = false
        an.physicsBody = a
        addChild(an)
        
        let j = SKPhysicsJointPin.joint(withBodyA: physicsBody, bodyB: a, anchor: an.position)
        j.shouldEnableLimits = false
        j.rotationSpeed = 0.5
        j.frictionTorque = 1
        world.add(j)
        
//        physicsBody.applyTorque(100)
//        let rotateAction = SKAction.rotate(byAngle: .pi / 2, duration: 1)
//        let repeatAction = SKAction.repeatForever(rotateAction)
//
//        chunk.run(repeatAction)
    }
}


extension World {
    private func generate() {
        removeChunks(chunks)
        
        let corePolygon = Polygon.make(radius: Const.coreRadius, vertexCount: 6)
        let coreChunk = Chunk(world: self, globalPolygon: corePolygon, material: Material(type: .obsidian), type: .core)
        core = coreChunk
        addChild(coreChunk)
        rotateChunk(coreChunk)
        
        let boundsPolygon = Polygon.make(radius: Const.planetRadius, vertexCount: 12)
        let boundsPolygons = boundsPolygon.split(minDistance: 40)
        let chunkPolygons = boundsPolygons.getDifference(from: [corePolygon])
        let groundChunks: [Chunk] = chunkPolygons.map { polygon in
            let type = groundMaterials.randomElement()!
            let material = Material(type: type)
            return Chunk(world: self, globalPolygon: polygon, material: material, type: .terrain)
        }
        addChunks(groundChunks)
    }
}
