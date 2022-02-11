//
//  ChunkNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit

final class ChunkNode: SKShapeNode {
    enum State {
        case stable
        case destroying
    }
    
    weak var terrain: TerrainNode?
    var model: Chunk!
    var state: State!
    
    private lazy var centerNode: SKShapeNode = {
        let n = SKShapeNode(circleOfRadius: 2)
        n.fillColor = .clear//.white
        n.strokeColor = .clear
        return n
    }()
    
    static func make(chunk: Chunk, terrain: TerrainNode?, state: State) -> ChunkNode {
        var drawPoints = chunk.polygon + (chunk.polygon.first == nil ? [] : [chunk.polygon.first!])
        let node = ChunkNode(points: &drawPoints, count: drawPoints.count)
        node.state = state
        node.model = chunk
        node.terrain = terrain
        
        node.position = chunk.position
//        node.strokeColor = .clear
        node.fillColor = chunk.material.color//.withAlphaComponent(0.5)
        node.setupPhysics(points: chunk.polygon)
        
        if state == .destroying {
            node.fillColor = chunk.material.color.withAlphaComponent(0.25)
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { t in
                node.explode()
            }
        }
        
        return node
    }
    
    private func setupPhysics(points: [CGPoint]) {
        guard points.count > 2 else { return }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = state == .destroying
        body.friction = 10
        body.restitution = 0

        body.categoryBitMask = Category.terrain.rawValue
        body.collisionBitMask = Category.unit.rawValue | Category.terrain.rawValue
        if state != .destroying {
            body.contactTestBitMask = Category.missle.rawValue
        }

        physicsBody = body
        
        addChild(centerNode)
    }
    
    func updateModel() {
        guard let terrain = terrain else {
            return
        }

        let newRotation = zRotation// + (terrain.zRotation ?? 0)
        let newPosition = position//convert(position, to: terrain)
        model.applyTransform(position: newPosition, rotation: newRotation)
    }
    
    func explode() {
        removeFromParent()
        terrain?.chunks.removeAll(where: { $0 === self })
    }
}
