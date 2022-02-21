//
//  GameScene.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit

final class GameScene: SKScene {
    private let contactProcessor = ContactProcessor()
    private let sceneCamera = SKCameraNode()
    
    private lazy var world: World = {
        let world = World()
        return world
    }()
    
    override func didMove(to view: SKView) {
        self.resetScene()
    }
    
    override func didSimulatePhysics() {
        super.didSimulatePhysics()
        sceneCamera.position = world.cameraCenter
        
        let sceneWidth = size.width / 1.1
        let cameraScale = 2 * Const.planetRadius / sceneWidth
        sceneCamera.xScale = cameraScale
        sceneCamera.yScale = cameraScale
        
        world.cleanUp()
    }
    
    func startFire() {
        world.player.fire()
    }
    
    func stopFire() {
//        playerNode?.weaponNode?.stopFire()
    }
    
    func changeWeapon(to weapon: WeaponType) {
        world.player.weapon = Weapon(world: world, type: weapon)
    }
    
    private func resetScene() {
        physicsWorld.removeAllJoints()
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = contactProcessor
        
        world.removeFromParent()
        addChild(world)
        
        sceneCamera.removeFromParent()
        addChild(sceneCamera)
        camera = sceneCamera
        
        world.setup()
    }
}
