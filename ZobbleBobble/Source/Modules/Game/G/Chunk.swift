//
//  Chunk.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit

enum ChunkType {
    case terrain
    case fragment
}

class Chunk: SKShapeNode {
    let world: World
    
    let type: ChunkType
    var polygon = [CGPoint]()
    var material: Material
    
    var globalPolygon: [CGPoint] {
        polygon.map { CGPoint(x: $0.x + position.x, y: $0.y + position.y).rotate(around: position, by: zRotation) }
    }
    
    init(world: World, globalPolygon: Polygon, material: Material, type: ChunkType) {
        let position = globalPolygon.centroid()
        self.world = world
        self.material = material
        self.type = type
        self.polygon = globalPolygon.map { CGPoint(x: $0.x - position.x, y: $0.y - position.y) }
        super.init()
        
        let path = CGMutablePath()
        path.addLines(between: polygon)
        path.closeSubpath()
        self.path = path
        
        self.position = position
        self.strokeColor = .clear
        self.fillColor = material.color.withAlphaComponent(0.2)
//        
//        let c = SKShapeNode(circleOfRadius: 2)
//        c.fillColor = .green
//        addChild(c)
        
        // Physics
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = true
        body.restitution = 0.6
//        body.linearDamping = 0
//        body.angularDamping = 0
        
        switch type {
        case .terrain:
            body.categoryBitMask = Category.terrain.rawValue
            body.collisionBitMask = Category.fragment.rawValue
            body.contactTestBitMask = Category.missle.rawValue
        case .fragment:
            body.categoryBitMask = Category.fragment.rawValue
            body.collisionBitMask = Category.unit.rawValue | Category.terrain.rawValue | Category.fragment.rawValue
            body.contactTestBitMask = Category.fragment.rawValue
        }
        self.physicsBody = body
        
        
//        if state == .destroying {
//            node.fillColor = chunk.material.color.withAlphaComponent(0.25)
//            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { t in
//                node.explode()
//            }
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(with node: SKNode, at world: SKPhysicsWorld) {
        guard let bodyA = physicsBody, let bodyB = node.physicsBody else { return }
        let anchor = CGPoint.zero//scene?.convertPoint(fromView: position) ?? position
        let joint = SKPhysicsJointFixed.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchor)
        world.add(joint)
    }
}
