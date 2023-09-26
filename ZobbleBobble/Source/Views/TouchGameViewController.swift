//
//  TouchGameViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import UIKit

final class GameViewController: UIViewController {
    private var game: MainGame?
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var tapGesture: UILongPressGestureRecognizer = {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(onTap))
        g.minimumPressDuration = 0
        g.requiresExclusiveTouchType = false
        g.delaysTouchesBegan = false
        g.delaysTouchesEnded = false
        return g
    }()
    
    private var isConfigured = false
    
    private var safeAreaRectangle: CGRect {
        var newSafeArea = view.safeAreaInsets
        newSafeArea.top /= view.frame.size.height
        newSafeArea.bottom /= view.frame.size.height
        newSafeArea.left /= view.frame.size.width
        newSafeArea.right /= view.frame.size.width
        
        return CGRect(x: newSafeArea.left,
                      y: newSafeArea.top,
                      width: 1 - newSafeArea.right - newSafeArea.left,
                      height: 1 - newSafeArea.bottom - newSafeArea.top)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if game == nil, renderView.bounds.width > 0 {
            let scale = UIScreen.main.scale
            let safeArea = safeAreaRectangle
            let size = newSize ?? CGSize(width: renderView.frame.width * scale, height: renderView.frame.height * scale)
            game = MainGame(screenSize: size, safeArea: safeArea, screenScale: scale)
        }
        updateGameSizeData()
    }
    
    @objc
    func onTap(_ sender: UILongPressGestureRecognizer) {
        var pos = sender.location(in: sender.view)
        pos.x *= UIScreen.main.scale
        pos.y *= UIScreen.main.scale
        
        switch sender.state {
        case .began:
            game?.onTouchDown(pos: pos)
        case .changed:
            game?.onTouchMove(pos: pos)
        case .ended:
            game?.onTouchUp(pos: pos)
        default:
            break
        }
    }
    
    private func updateGameSizeData(newSize: CGSize? = nil) {
        let scale = UIScreen.main.scale
        let safeArea = safeAreaRectangle
        let size = newSize ?? CGSize(width: renderView.frame.width * scale, height: renderView.frame.height * scale)
        
        guard let game = game, size != .zero else { return }
        
        let needsRebuild = newSize != game.screenSize || scale != game.screenScale
        if needsRebuild {
            renderView.resetRenderer(delegate: self, dataSource: game, renderSize: size)
        }
        game.updateSceneSize(newScreenSize: size, newSafeArea: safeArea, newScreenScale: scale)
    }
}

extension GameViewController: RenderDelegate {
    func rendererSizeDidChange(size: CGSize) {
        updateGameSizeData(newSize: size)
    }
    
    func updateRenderData(time: TimeInterval) {
        guard let game = game else { return }
        game.update(time)
    }
}
