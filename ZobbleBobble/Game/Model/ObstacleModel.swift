//
//  ObstacleModel.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import Foundation
import Box2D

class ObstacleModel: Object {
    
    var type: ObjectType { .obstacle }
    var id: String = UUID().uuidString
    
    var body: b2Body?
    
    var position: PointModel {
        PointModel(x: chunkPosition.x + positionInChunk.x, y: chunkPosition.y + positionInChunk.y)
    }
    var chunkPosition: PointModel
    var positionInChunk: PointModel
    var points: [PointModel]
    
    init(chunkPosition: PointModel, points: [PointModel]) {
        self.positionInChunk = PointModel(x: 0, y: 0)
        self.chunkPosition = chunkPosition
        self.points = points
    }
    
    func update() {
        guard let body = body else { return }
        positionInChunk = PointModel(x: body.position.x - chunkPosition.x, y: body.position.y - chunkPosition.y)
    }
    
    func makeBody(world: b2World) {
        let bd = b2BodyDef()
        let pos = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
        bd.position = b2Vec2(cgPoint: pos)
        
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
        let points = self.points.map { b2Vec2($0.x, $0.y) }
        shape.set(vertices: points)
        fd.shape = shape
          
        body.createFixture(fd)
//        body.userData = self
        
        self.body = body
    }
    
    func destroyBody(world: b2World) {
        guard let body = body else { return }
        world.destroyBody(body)
        self.body = nil
    }
}
