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
    private var game: Game?
    
    lazy var gesture: UIGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(onTap(gr:)))
        g.delegate = self
        return g
    }()
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView()
        view.colorPixelFormat = .rgba8Unorm
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var exitButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .red
        b.setTitle("EXIT", for: .normal)
        b.addTarget(self, action: #selector(onExitTap), for: .touchUpInside)
        return b
    }()
    
    var renderDataProvider: RenderDataSource? {
        game
    }
    
    
    init() {
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.game = Game()
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        renderView.addGestureRecognizer(gesture)
        
        view.addSubview(exitButton)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: exitButton, attribute: .leading, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: exitButton, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: exitButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 120),
            NSLayoutConstraint(item: exitButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc
    private func onExitTap() {
        switch game?.state {
        case .menu(let n):
            game?.changeState(to: .level(n))
        case .level(let n):
            game?.changeState(to: .menu(n))
        default:
            break
        }
    }
    
    
    
    @objc
    private func update(displayLink: CADisplayLink) {
        guard let game = game else { return }
//        DispatchQueue.global().async {
//            self.lock.lock()
        game.update(displayLink.duration)
//            self.lock.unlock()
//        }
        renderView.dataSource = game
        renderView.update(cameraScale: game.cameraScale)
//        renderView.setRenderData(polygonMesh: world.polygonMesh, circleMesh: world.circleMesh, liquidMesh: world.liquidMesh)
    }
    
    @objc
    private func onTap(gr: UIGestureRecognizer) {
        var position = gr.location(in: gr.view)
        position.x -= renderView.frame.width / 2
        position.y -= renderView.frame.height / 2
        game?.onTap(at: position)
        
    }
}

extension GameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        true
    }
}
