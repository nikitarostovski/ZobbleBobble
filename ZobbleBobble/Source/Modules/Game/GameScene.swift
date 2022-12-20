//
//  GameScene.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit
import ZobbleCore

final class GameScene: SKScene {
    private let contactProcessor = ContactProcessor()
    private let sceneCamera = SKCameraNode()
    
    private lazy var world: World = {
        let level = LevelParser.parse(UIImage(named: "Level")!)
        let world = World(level: level, camera: sceneCamera)
        return world
    }()
    
    override func didMove(to view: SKView) {
        self.resetScene()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateCamera()
    }
    
    private func resetScene() {
        world.removeFromParent()
        addChild(world)
        
//        sceneCamera.removeFromParent()
//        addChild(sceneCamera)
        camera = sceneCamera
    }
    
    private func updateCamera() {
//        world.updateCamera(camera: sceneCamera)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let first = touches.first {
            let location = first.location(in: first.view)
            world.onTouch(position: location)
        }
    }
}
