//
//  Obstacle.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 14.11.2020.
//

import SpriteKit
import Box2D

class Obstacle: SKShapeNode {
    
    private let size: CGSize
    
    var body: b2Body!
    
    init(world: b2World, pos: CGPoint? = nil, size: CGSize? = nil) {
        let size = size ?? CGSize(width: 10, height: 10)
        self.size = size
        super.init()
        
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        path = CGPath(rect: rect, transform: nil)
        
        fillColor = .red
        
        body = makeBody(world: world, pos: pos)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeClone(world: b2World) -> b2Body {
        let clone = makeBody(world: world, pos: body.position.cgPoint)
        return clone
    }
    
    func update() {
        position = body.position.cgPoint
        zRotation = CGFloat(body.angle)
    }
    
    private func makeBody(world: b2World, pos: CGPoint? = nil) -> b2Body {
        let bd = b2BodyDef()
        if let pos = pos {
            position = pos
            bd.position = b2Vec2(cgPoint: pos)
        }
        bd.type = b2BodyType.kinematicBody
        let body = world.createBody(bd)
        
        let fd = b2FixtureDef()
        fd.friction = 0.2
        fd.restitution = 0.2
        fd.density = 1
        fd.isSensor = false
        fd.filter.categoryBits = CollisionType.obstacle.rawValue
        fd.filter.maskBits = CollisionType.obstacle.rawValue | CollisionType.player.rawValue
        
        let shape = b2PolygonShape()
        shape.setAsBox(halfWidth: b2Float(size.width / 2), halfHeight: b2Float(size.height / 2))
        fd.shape = shape
          
        body.createFixture(fd)
        
        return body
    }
}
