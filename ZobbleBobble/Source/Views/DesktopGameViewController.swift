//
//  DesktopGameViewController.swift
//  ZobbleBobble
//
//  Created by Rost on 19.08.2023.
//

import Cocoa
import MetalKit

//class Abc: NSObject {
//    var panel: NSPanel!
//
//    func buildWnd2() {
//        let _panelW : CGFloat = 200
//        let _panelH : CGFloat = 200
//
//        panel = NSPanel(contentRect:NSMakeRect(9300, 1300, _panelW, _panelH), styleMask:[.titled, .closable, .utilityWindow],
//                        backing:.buffered, defer: false)
//        panel.isFloatingPanel = true
//        panel.title = "NSPanel"
//        panel.orderFront(nil)
//    }
//}
//
//let abc = Abc()

final class GameViewController: NSViewController {
    private var game: MainGame?
    
    lazy var renderView: MetalRenderView = {
        let view = MetalRenderView()
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
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        game = MainGame()
        
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: renderView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: renderView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        updateGameSizeData()
    }
    
    override func mouseDown(with event: NSEvent) {
        var pos = event.locationInWindow
        pos.y = view.bounds.height - pos.y
        pos.x *= NSScreen.main?.backingScaleFactor ?? 1
        pos.y *= NSScreen.main?.backingScaleFactor ?? 1
        game?.onTouchDown(pos: pos)
    }
    
    override func mouseDragged(with event: NSEvent) {
        var pos = event.locationInWindow
        pos.y = view.bounds.height - pos.y
        pos.x *= NSScreen.main?.backingScaleFactor ?? 1
        pos.y *= NSScreen.main?.backingScaleFactor ?? 1
        game?.onTouchMove(pos: pos)
    }
    
    override func mouseUp(with event: NSEvent) {
        var pos = event.locationInWindow
        pos.y = view.bounds.height - pos.y
        pos.x *= NSScreen.main?.backingScaleFactor ?? 1
        pos.y *= NSScreen.main?.backingScaleFactor ?? 1
        game?.onTouchUp(pos: pos)
    }
    
    private func updateGameSizeData(newSize: CGSize? = nil) {
        let scale = NSScreen.main?.backingScaleFactor ?? 1
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
