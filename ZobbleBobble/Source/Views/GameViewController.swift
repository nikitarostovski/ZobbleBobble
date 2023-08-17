//
//  GameViewController.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import UIKit

final class GameViewController: UIViewController {
    var screenSize: CGSize { UIScreen.main.bounds.size }
    
    private var game: Game?
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView(screenSize: screenSize, delegate: self, dataSource: game)
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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.game = Game(delegate: self, scrollHolder: self, screenSize: screenSize)
        
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
        guard !isConfigured else { return }
        isConfigured = true
        game?.runMenu()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let pos = touch.location(in: touch.view)
        game?.onTouchDown(pos: pos)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let pos = touch.location(in: touch.view)
        game?.onTouchMove(pos: pos)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let pos = touch.location(in: touch.view)
        game?.onTouchUp(pos: pos)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        let pos = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
        game?.onTouchUp(pos: pos)
    }
}

extension GameViewController: RenderViewDelegate {
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

