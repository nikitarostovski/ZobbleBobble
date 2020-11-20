//
//  Game.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import Foundation
import SpriteKit
import Box2D

final class Game {
    
    let physicsQueue = DispatchQueue.global(qos: .userInitiated)
    
    private let gravity: b2Float = 10
    private let velocityIterations = 1
    private let positionIterations = 1
    
    private var world: b2World
    private var displayLink: CADisplayLink?
    private var startTouchLocation: CGPoint?
    
    var viewport: CGSize = CGSize(width: 1, height: 1)
    var center: CGPoint = .zero
    
    var player: PlayerModel
    var chunkMap: ChunkMap
    
    var obstacles: [ObstacleModel] {
        chunkMap.visibleChunks.flatMap { $0.obstacles }
    }
    
    init() {
        chunkMap = ChunkMap()
        world = b2World(gravity: b2Vec2(0, -gravity))
        player = PlayerModel(position: PointModel(x: 50, y: 50), radius: 2)
        
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
        
        player.makeBody(world: world)
    }
    
    // MARK: - Public
    
    func touchDown(_ point: CGPoint) {
        startTouchLocation = point
    }
    
    func touchMove(_ point: CGPoint) {
        
    }
    
    func touchUp(_ point: CGPoint) {
        guard let startTouchLocation = startTouchLocation else { return }
        let impulse = makeImpulse(start: startTouchLocation, end: point)
        player.applyImpulse(impulse)
        self.startTouchLocation = nil
    }
    
    // MARK: - Private
    
    private func updateChunksIfNeeded() {
        let result = chunkMap.updateChunksIfNeeded(position: CGPoint(x: center.x - viewport.width / 2, y: center.y - viewport.height / 2), viewport: viewport)
        
        result.toRemove.forEach { chunk in
            chunk.obstacles.forEach { obstacle in
                DispatchQueue.main.async {
                    obstacle.destroyBody(world: self.world)
                }
            }
        }
        
        result.toAdd.forEach { [weak self] chunk in
            chunk.obstacles.forEach { obstacle in
                guard let self = self, obstacle.body == nil else { return }
                DispatchQueue.main.async {
                    obstacle.makeBody(world: self.world)
                }
            }
        }
//        print("visible obstacle count: \(obstacles.count). bodies: \(world.bodyCount)")
    }
    
    @objc private func step() {
            let dt = b2Float(self.displayLink?.duration ?? 0)
            self.world.step(timeStep: dt, velocityIterations: self.velocityIterations, positionIterations: self.positionIterations)
        
        physicsQueue.async {
            self.updateChunksIfNeeded()
        }
        self.updateModels()
    }
    
    private func updateModels() {
        player.update()
        obstacles.forEach { $0.update() }
    }
    
    private func makeImpulse(start: CGPoint, end: CGPoint) -> CGVector {
        let distance = end.distance(to: start)
        let angle = end.angle(to: start)
        
        let normX = cos(angle)
        let normY = sin(angle)
        
        let power = distance * 1000
        
        let vector = CGVector(dx: power * normX, dy: power * normY)
        return vector
    }
}
