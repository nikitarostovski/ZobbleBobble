//
//  GameScene.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class GameScene: SKScene {
    
    private let matrixSize = 32
    
    let sceneCamera = SKCameraNode()
    
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
        
        // terrain
        let terrainSize = CGSize(width: min(size.width, size.height),
                                 height: min(size.width, size.height))
        
        let generatedData = MatrixGenerator.generate(size: matrixSize, unitCount: 3)
        let matrix = generatedData.0
        let spawnPoints = generatedData.1
        
        var polygons = PolygonConverter.makeWalls(from: matrix)
        polygons = polygons.map { $0.map { CGPoint(x: $0.x * terrainSize.width, y: $0.y * terrainSize.height) } }
        terrain = Terrain(polygons: polygons)
        
        addChild(terrain)
        
        // units
        for pt in spawnPoints {
            let unit = Unit.make(at: CGPoint(x: CGFloat(pt.0) / CGFloat(matrixSize) * terrainSize.width,
                                             y: CGFloat(pt.1) / CGFloat(matrixSize) * terrainSize.height))
            addChild(unit)
            player = unit
        }
        
        // camera
        addChild(sceneCamera)
        sceneCamera.position = CGPoint(x: terrainSize.width / 2, y: terrainSize.height / 2)
        camera = sceneCamera
        //        sceneCamera.setScale(1.05)
        
        // physics
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
