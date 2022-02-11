//
//  CoreNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 24.01.2022.
//

import SpriteKit

final class CoreNode: SKShapeNode {
    weak var terrain: TerrainNode?
    var model: Chunk!
    
    private lazy var centerNode: SKShapeNode = {
        let n = SKShapeNode(circleOfRadius: 2)
        n.fillColor = .clear//.white
        n.strokeColor = .clear
        return n
    }()
    
    static func make(chunk: Chunk, terrain: TerrainNode?) -> CoreNode {
        var drawPoints = chunk.polygon + (chunk.polygon.first == nil ? [] : [chunk.polygon.first!])
        let node = CoreNode(points: &drawPoints, count: drawPoints.count)
        node.model = chunk
        node.terrain = terrain
        
        node.position = chunk.position
//        node.strokeColor = .clear
        node.fillColor = chunk.material.color//.withAlphaComponent(0.5)
        node.setupPhysics(points: chunk.polygon)
        
        return node
    }
    
    private func setupPhysics(points: [CGPoint]) {
        guard points.count > 2 else { return }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = false
        body.friction = 10
        body.restitution = 0

        body.categoryBitMask = Category.terrain.rawValue
        body.collisionBitMask = Category.unit.rawValue | Category.terrain.rawValue
        body.contactTestBitMask = Category.missle.rawValue

        physicsBody = body
        
        addChild(centerNode)
    }
    
    func updateModel() {
        guard let terrain = terrain else {
            return
        }

        let newRotation = zRotation
        let newPosition = terrain.convert(position, from: self)//convert(position, to: terrain)
        model.applyTransform(position: newPosition, rotation: newRotation)
    }
    
    func explode() {
        removeFromParent()
        terrain?.chunks.removeAll(where: { $0 === self })
    }
}
