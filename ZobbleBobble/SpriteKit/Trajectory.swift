//
//  Trajectory.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 16.11.2020.
//

import SpriteKit
import Box2D

final class Trajectory: SKNode {
    
    let velocityIterations: Int
    let positionIterations: Int
    
    private weak var player: Player?
    
    private var worldClone: b2World
    private var playerClone: b2Body
    
    private var dots: [SKShapeNode] = []
    
    var impulse: b2Vec2?
    var step: b2Float = 0
    
    init(world: b2World, player: Player, obstacles: [Obstacle], velocityIterations: Int, positionInterations: Int) {
        self.velocityIterations = velocityIterations
        self.positionIterations = positionInterations
        self.player = player
        
        let worldClone = b2World(gravity: world.gravity)
        self.worldClone = worldClone
        self.playerClone = player.makeClone(world: worldClone)
        obstacles.forEach { let _ = $0.makeClone(world: worldClone) }
        
        super.init()
        setupDots()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(step: b2Float) {
        guard let player = player else { return }
        self.step = step
        
        playerClone.setTransform(position: player.body.position, angle: player.body.angle)
        playerClone.linearVelocity = player.body.linearVelocity
        playerClone.angularVelocity = player.body.angularVelocity
        if let impulse = impulse {
            playerClone.applyLinearImpulse(impulse, point: playerClone.localCenter, wake: true)
        }
        
        updateDots()
    }
    
    func showTrajectory() {
        dots.forEach { $0.isHidden = false }
    }
    
    func hideTrajectory() {
        dots.forEach { $0.isHidden = true }
    }
    
    private func setupDots() {
        dots.forEach {
            $0.removeFromParent()
        }
        dots.removeAll()
        for _ in 0 ..< 30 {
            let node = SKShapeNode(circleOfRadius: 1)
            addChild(node)
            dots.append(node)
        }
        hideTrajectory()
    }
    
    private func updateDots() {
        for i in 0 ..< dots.count {
            let alpha = CGFloat(i) / CGFloat(dots.count)
            for _ in 0 ..< 7 {
                worldClone.step(timeStep: step, velocityIterations: velocityIterations, positionIterations: positionIterations)
            }
            dots[i].position = playerClone.position.cgPoint
            dots[i].alpha = 1 - alpha
        }
    }
}
