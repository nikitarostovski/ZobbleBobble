//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 13.11.2020.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet weak var skView: SKView! {
        didSet {
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
        }
    }
    
    var game = Game()
    
    lazy var renderer: Renderer = {
        let renderer = Renderer(size: skView.bounds.size, game: game)
        renderer.scaleMode = .resizeFill
        renderer.onUpdate = rendererUpdate
        return renderer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        skView.presentScene(renderer)
    }
    
    private func rendererUpdate() {
        game.center = renderer.center
        game.viewport = renderer.viewport
        renderer.update()
    }
}

extension GameViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let location = touches.first?.location(in: view) else { return }
        game.touchDown(location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let location = touches.first?.location(in: view) else { return }
        game.touchMove(location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let location = touches.first?.location(in: view) else { return }
        game.touchUp(location)
    }
}
