//
//  GameScene.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class GameScene: SKScene {
    
    let sceneCamera = SKCameraNode()
    
    let contactProcessor = ContactProcessor()
    var terrain: Terrain!
    var player: Unit!
    
    var previousCameraScale = CGFloat()
    var cameraScale: CGFloat = 1 {
        didSet {
            sceneCamera.setScale(cameraScale)
        }
    }
    
    override func didMove(to view: SKView) {
        self.resetScene()
    }
    
    func resetScene() {
        previousCameraScale = CGFloat()
        cameraScale = 1
        removeAllChildren()
        
        guard let levelURL = Bundle.main.url(forResource: "Level", withExtension: "lvl"),
              let levelData = try? Data(contentsOf: levelURL),
              let level = Level.load(json: levelData)
        else {
            return
        }
        // terrain
        let terrainSize = CGSize(width: min(size.width, size.height),
                                 height: min(size.width, size.height))
        
        let polygons = level.polygons.map { $0.map { CGPoint(x: $0.x * terrainSize.width / level.width,
                                                             y: $0.y * terrainSize.height / level.height) } }
        terrain = Terrain(polygons: polygons)
        addChild(terrain)
        
        
        // units
        for pt in [level.playerPosition!] {
            let unit = Unit.make(at: CGPoint(x: pt.x * terrainSize.width / level.width,
                                             y: pt.y * terrainSize.height / level.height))
            addChild(unit)
            player = unit
        }
        
        // camera
        addChild(sceneCamera)
        sceneCamera.position = CGPoint(x: terrainSize.width / 2, y: terrainSize.height / 2)
        camera = sceneCamera
        //        sceneCamera.setScale(1.05)
        
        // physics
        physicsWorld.contactDelegate = contactProcessor
        physicsWorld.gravity = .zero
        //        physicsWorld.speed = 1.2
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
}

// MARK: - Interaction

extension GameScene {
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        camera?.position.x -= location.x - previousLocation.x
        camera?.position.y -= location.y - previousLocation.y
    }
    
    @objc func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            previousCameraScale = sceneCamera.xScale
        }
        let newScale = previousCameraScale * 1 / sender.scale
        cameraScale = newScale
    }
    
    func fireTap() {
        player.fire()
    }
}
