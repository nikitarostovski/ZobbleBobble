//
//  PlayerModel.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import Foundation
import Box2D

class PlayerModel: Object {
 
    var type: ObjectType { .player }
    var id: String = UUID().uuidString
    
    var body: b2Body?
    
    var position: PointModel
    var radius: Float
    
    init(position: PointModel, radius: Float) {
        self.position = position
        self.radius = radius
    }
    
    func update() {
        guard let body = body else { return }
        position = PointModel(x: body.position.x, y: body.position.y)
    }
    
    func makeBody(world: b2World) {
        let bd = b2BodyDef()
        let pos = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
        bd.position = b2Vec2(cgPoint: pos)
        
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
//        body.userData = self
        
        self.body = body
    }
    
    func applyImpulse(_ impulse: CGVector) {
        guard let body = body else { return }
        let vector = b2Vec2(b2Float(impulse.dx), b2Float(-impulse.dy))
        body.applyLinearImpulse(vector, point: body.localCenter, wake: true)
    }
}
