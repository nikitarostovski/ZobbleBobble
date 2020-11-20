//
//  Landscape.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import CoreGraphics
import SpriteKit
import Box2D

final class Landscape: SKNode {
    
    var world: b2World
    
    var obstacles: [Obstacle] = []
    
    init(world: b2World) {
        self.world = world
        super.init()
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        obstacles.forEach {
            $0.update()
        }
    }
    
    private func setup() {
        self.obstacles = [
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0, y: 1)), size: CGSize(width: 20, height: 100000)),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 1, y: 1)), size: CGSize(width: 20, height: 100000)),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.1, y: 0.1))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.4, y: 0.2))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.2, y: 0.3))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.8, y: 0.4))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.5, y: 0.5))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.6, y: 0.6))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.2, y: 0.7))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.3, y: 0.8))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.9, y: 0.9))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.6, y: 1.0))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.2, y: 1.1))),
            Obstacle(world: world, pos: convertPoint(CGPoint(x: 0.3, y: 1.2))),
        ]
        self.obstacles.forEach {
            addChild($0)
        }
    }
    
    func convertPoint(_ pos: CGPoint) -> CGPoint {
        return CGPoint(x: frame.width * pos.x, y: frame.height * (1.0 - pos.y))
    }
}
