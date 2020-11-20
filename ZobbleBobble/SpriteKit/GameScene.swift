//
//  GameScene.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 13.11.2020.
//

import SpriteKit
import GameplayKit
import Box2D

class GameScene: SKScene {
    
    // MARK: - Constants
    
    let gravity: b2Float = 10
    let startY: CGFloat = 0.25
    let velocityIterations = 1
    let positionIterations = 1
    
    // MARK: - Variables
    
    var displayLink: CADisplayLink!
    
    var startTouchLocation: CGPoint?
//    var startTouchTime: Date?
    
    var playerCamera: SKCameraNode!
    
    var sceneNode: SKNode!
    var player: Player!
    var trajectory: Trajectory?
    var landscape: Landscape!
    
    var world: b2World!
    
    var level: LevelModel
    
    var step: b2Float {
        get {
            let step: b2Float
            if startTouchLocation != nil {
                step = b2Float(displayLink.duration) * 0.2
            } else {
                step = b2Float(displayLink.duration)
            }
            return step
        }
    }
    
    // MARK: - Lifecycle
    
//    override init(size: CGSize) {
//        
//        if let filepath = Bundle.main.path(forResource: "Level", ofType: "json"),
//           let contents = try? String(contentsOfFile: filepath) {
//            
////            if let level = LevelModel.makeLevel(withJSON: contents) {
////                self.level = level
////            } else {
////                fatalError()
////
////            }
//        } else {
//            fatalError()
//        }
//        super.init(size: size)
//        
//        setupWorld()
//        setupLandscape()
//        setupPlayer()
//        setupTrajectory()
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func displayUpdate() {
        world.step(timeStep: step, velocityIterations: velocityIterations, positionIterations: positionIterations)
        
        if startTouchLocation != nil {
            trajectory?.update(step: step)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        player.update()
        landscape.update()
    }
}
