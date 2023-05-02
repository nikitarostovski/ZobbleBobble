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
    var screenSize: CGSize { UIScreen.main.bounds.size }
    var renderSize: CGSize { CGSize(width: UIScreen.main.nativeBounds.size.width / Settings.resolutionDownscale,
                                    height: UIScreen.main.nativeBounds.size.height / Settings.resolutionDownscale) }
//    var physicsSize: CGSize { CGSize(width: Settings.worldWidth,
//                                     height: Settings.worldWidth / UIScreen.main.bounds.width * UIScreen.main.bounds.height) }
    
    private var game: Game?
    
    lazy var tapGesture: UIGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(onTap(gr:)))
        g.delegate = self
        return g
    }()
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView(screenSize: screenSize, renderSize: renderSize)
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
    
    lazy var controlsBar: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [exitButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        return stack
    }()
    
    lazy var exitButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .red
        b.setTitle("EXIT", for: .normal)
        b.addTarget(self, action: #selector(onExitTap), for: .touchUpInside)
        return b
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
        
        self.game = Game(delegate: self, scrollHolder: self, screenSize: screenSize, renderSize: renderSize)
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        
        view.addSubview(swipeControl)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: swipeControl, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: swipeControl, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: swipeControl, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: swipeControl, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        swipeControl.addGestureRecognizer(tapGesture)
        
        view.addSubview(controlsBar)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: controlsBar, attribute: .leading, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: controlsBar, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 20),
//            NSLayoutConstraint(item: controlsBar, attribute: .trailing, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: controlsBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        ])
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(displayLink:)))
        displayLink.add(to: .main, forMode: .common)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isConfigured else { return }
        isConfigured = true
        game?.runMenu()
    }
    
    @objc
    private func onExitTap() {
        game?.onExitTap()
    }
    
    @objc
    private func update(displayLink: CADisplayLink) {
        guard let game = game else { return }
        
        game.update(displayLink.duration)
        
        renderView.backgroundDataSource = game.backgroundDataSource
        renderView.objectsDataSource = game.objectsDataSource
        renderView.starsDataSource = game.starsDataSource
        renderView.cameraDataSource = game.cameraDataSource
    }
    
    @objc
    private func onTap(gr: UIGestureRecognizer) {
        var position = gr.location(in: renderView)
        
        position.x = position.x - renderView.frame.width / 2
        position.y = position.y - renderView.frame.height / 2
        game?.onTap(at: position)
    }
}

extension GameViewController: GameDelegate {
    func gameDidChangeState(_ game: Game) {
        switch game.state.state {
        case .level:
            controlsBar.isHidden = false
        default:
            controlsBar.isHidden = true
        }
    }
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

