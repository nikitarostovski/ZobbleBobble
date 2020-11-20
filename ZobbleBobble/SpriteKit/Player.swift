//
//  Player.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 13.11.2020.
//

import SpriteKit
import Box2D

class Player: SKShapeNode {
    
    private var radius: CGFloat
    
    var body: b2Body!
    
    init(world: b2World, radius: CGFloat, pos: CGPoint? = nil) {
        self.radius = radius
        super.init()
        
        path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        fillColor = .blue
        
        body = makeBody(world: world, pos: pos)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeClone(world: b2World) -> b2Body {
        let clone = makeBody(world: world, pos: body.position.cgPoint)
        clone.linearVelocity = body.linearVelocity
        return clone
    }
    
    func update() {
        position = body.position.cgPoint
        zRotation = CGFloat(body.angle)
    }
    
    func applyImpulse(_ impulse: CGVector) {
        body.applyLinearImpulse(b2Vec2(cgVector: impulse), point: body.localCenter, wake: true)
    }
    
    private func makeBody(world: b2World, pos: CGPoint? = nil) -> b2Body {
        let bd = b2BodyDef()
        if let pos = pos {
            position = pos
            bd.position = b2Vec2(cgPoint: pos)
        }
        bd.type = b2BodyType.dynamicBody
        bd.bullet = true
        let body = world.createBody(bd)
        
        let fd = b2FixtureDef()
        fd.friction = 0.2
        fd.restitution = 0.2
        fd.density = 0.1
        fd.isSensor = false
        fd.filter.categoryBits = CollisionType.player.rawValue
        fd.filter.maskBits = CollisionType.obstacle.rawValue
        
        let shape = b2CircleShape()
        shape.radius = b2Float(radius)
        fd.shape = shape
          
        body.createFixture(fd)
        
        return body
    }
}
