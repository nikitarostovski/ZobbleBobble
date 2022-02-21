//
//  Core.swift
//  ZobbleBobble
//
//  Created by Rost on 15.02.2022.
//

import SpriteKit

class Core: SKShapeNode {
    let world: World
    var polygon = [CGPoint]()
    
    var globalPolygon: [CGPoint] {
        polygon.map { CGPoint(x: $0.x + position.x, y: $0.y + position.y).rotate(around: position, by: zRotation) }
    }
    
    init(world: World, globalPolygon: Polygon) {
        let position = globalPolygon.centroid()
        self.world = world
        self.polygon = globalPolygon.map { CGPoint(x: $0.x - position.x, y: $0.y - position.y) }
        super.init()
        
        let path = CGMutablePath()
        path.addLines(between: polygon)
        path.closeSubpath()
        self.path = path
        
        self.position = position
        self.strokeColor = .clear
        self.fillColor = UIColor.white
        
        // Physics
        let body = SKPhysicsBody(polygonFrom: path)
        
        body.isDynamic = false
        body.density = 10
        body.linearDamping = 0
        body.angularDamping = 0
        
        body.categoryBitMask = Category.core.rawValue
        body.collisionBitMask = Category.missle.rawValue
        body.contactTestBitMask = Category.missle.rawValue
        
        self.physicsBody = body
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
