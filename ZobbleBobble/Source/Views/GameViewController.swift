//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import UIKit

final class GameViewController: UIViewController {
    private var game: Game?
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView(delegate: self, dataSource: game)
        view.colorPixelFormat = .bgra8Unorm
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var swipeControl: SwipeView = {
        let view = SwipeView(delegate: self)
//        view.backgroundColor = .red.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.game = Game(delegate: self, scrollHolder: self, screenSize: UIScreen.main.nativeBounds.size, safeArea: safeAreaRectangle)
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        
//        view.addSubview(swipeControl)
//        NSLayoutConstraint.activate([
//            NSLayoutConstraint(item: swipeControl, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: swipeControl, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: swipeControl, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: swipeControl, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
//        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let newSafeAreaRect = safeAreaRectangle
        if let game = game, newSafeAreaRect != game.safeArea {
            game.safeArea = newSafeAreaRect
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        var pos = touch.location(in: touch.view)
        pos.x *= UIScreen.main.scale
        pos.y *= UIScreen.main.scale
        game?.onTouchDown(pos: pos)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        var pos = touch.location(in: touch.view)
        pos.x *= UIScreen.main.scale
        pos.y *= UIScreen.main.scale
        game?.onTouchMove(pos: pos)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        var pos = touch.location(in: touch.view)
        pos.x *= UIScreen.main.scale
        pos.y *= UIScreen.main.scale
        game?.onTouchUp(pos: pos)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        let pos = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
        game?.onTouchUp(pos: pos)
    }
}

extension GameViewController: RenderViewDelegate {
    func rendererSizeDidChange(size: CGSize) {
        game?.screenSize = size
    }
    
    func updateRenderData(time: TimeInterval) {
        guard let game = game else { return }
        game.update(time)
    }
}

extension GameViewController: GameDelegate {
    func gameDidChangeState(_ game: Game) { }
}

extension GameViewController: ScrollHolder {
    func updateScrollPosition(pageCount: Int, selectedPage: Int) {
        swipeControl.pageSize = renderView.bounds.width
        swipeControl.maxSize = swipeControl.pageSize * CGFloat(pageCount)
        swipeControl.scrollView.setContentOffset(CGPoint(x: CGFloat(selectedPage) * swipeControl.pageSize, y: 0), animated: false)
    }
}

extension GameViewController: SwipeViewDelegate {
    func swipeViewDidSwipe(_ swipeView: SwipeView, totalOffset: CGPoint) {
        game?.onSwipe(totalOffset)
    }
}

extension GameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

