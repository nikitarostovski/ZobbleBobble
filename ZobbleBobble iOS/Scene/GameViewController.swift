//
//  GameViewController.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    lazy var scene: GameScene = {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        return scene
    }()
    
    lazy var sceneView: SKView = {
        let sceneView = SKView(frame: view.bounds)
        sceneView.showsFPS = true
        sceneView.ignoresSiblingOrder = true
        sceneView.contentMode = .scaleToFill
        return sceneView
    }()
    
    lazy var controlPad: ControlPad = {
        let controlPad = ControlPad()
        controlPad.onFire = scene.fireTap
        controlPad.onReset = scene.resetScene
        return controlPad
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneView)
        sceneView.presentScene(scene)
        
        view.addSubview(controlPad)
        
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.addTarget(scene, action: #selector(GameScene.pinchGestureAction(_:)))
        view?.addGestureRecognizer(pinchGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLoad()
        sceneView.frame = view.bounds
        controlPad.frame = CGRect(x: 0, y: view.bounds.height - 100, width: view.bounds.width, height: 100)
    }
}
