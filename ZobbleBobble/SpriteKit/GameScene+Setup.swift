//
//  GameScene+Setup.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 15.11.2020.
//

import SpriteKit
import Box2D

extension GameScene {
    
    func setupWorld() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayUpdate))
        displayLink.add(to: .current, forMode: .common)
        
        playerCamera = SKCameraNode()
        addChild(playerCamera)
        self.camera = playerCamera
        
        sceneNode = SKNode()
        addChild(sceneNode)
        
        world = b2World(gravity: b2Vec2(0, -gravity))
    }
    
    func setupTrajectory() {
//        trajectory = Trajectory(world: world, player: player, obstacles: obstacles, velocityIterations: velocityIterations, positionInterations: positionIterations)
//        sceneNode.addChild(trajectory)
    }
    
    func setupLandscape() {
        landscape = Landscape(world: world)
        sceneNode.addChild(landscape)
    }
    
    func setupPlayer() {
        let pos = convertPoint(CGPoint(x: 0.5, y: 1 - startY))
        
        let player = Player(world: world, radius: 15, pos: pos)
        sceneNode.addChild(player)
        self.player = player
    }
    
    func convertPoint(_ pos: CGPoint) -> CGPoint {
        return CGPoint(x: frame.width * pos.x, y: frame.height * (1.0 - pos.y))
    }
}
