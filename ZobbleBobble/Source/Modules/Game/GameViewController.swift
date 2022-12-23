//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import UIKit
import SpriteKit
import ZobbleCore

final class GameViewController: UIViewController {
    private lazy var world: World = {
        let level = LevelParser.parse(UIImage(named: "Level")!)
        let world = World(level: level)
        
        world.spawnCore(at: .zero)
        
        return world
    }()
    
    lazy var gesture: UIGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(onTap(gr:)))
        g.delegate = self
        return g
    }()
    
    lazy var renderView: RenderView = {
        let view = MetalRenderView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        renderView.addGestureRecognizer(gesture)
        
        renderView.setUniformData(particleRadius: Float(world.particleRadius))
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .default)
    }
    
    var date = Date()
    let queue = DispatchQueue(label: "ttt", qos: .background)
    let lock = NSLock()
    
    @objc
    private func update(displayLink: CADisplayLink) {
//        DispatchQueue.global().async {
//            self.lock.lock()
            self.world.update(displayLink.duration)
//            self.lock.unlock()
//        }
        renderView.setRenderData(polygonMesh: world.polygonMesh, circleMesh: world.circleMesh, liquidMesh: world.liquidMesh)
    }
    
    @objc
    private func onTap(gr: UIGestureRecognizer) {
        var position = gr.location(in: gr.view)
        position.x -= renderView.frame.width / 2
        position.y -= renderView.frame.height / 2
        world.spawnComet(at: position)
    }
}

extension GameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        true
    }
}
