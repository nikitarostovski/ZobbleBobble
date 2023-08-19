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
    private var game: Game?
    
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
        
        self.game = Game(delegate: self, scrollHolder: self)
        
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
    
    override func mouseMoved(with event: NSEvent) {
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

extension GameViewController: RenderViewDelegate {
    func rendererSizeDidChange(size: CGSize) {
        updateGameSizeData(newSize: size)
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
    func updateScrollPosition(pageCount: Int, selectedPage: Int) { }
}

//class AppDelegate: NSObject, NSApplicationDelegate {
//    var window:NSWindow!
//
//    @objc func myBtnAction(_ sender:AnyObject ) {
//        abc.buildWnd2()
//    }
//
//    func buildMenu() {
//        let mainMenu = NSMenu()
//        NSApp.mainMenu = mainMenu
//        // **** App menu **** //
//        let appMenuItem = NSMenuItem()
//        mainMenu.addItem(appMenuItem)
//        let appMenu = NSMenu()
//        appMenuItem.submenu = appMenu
//        appMenu.addItem(withTitle: "Quit", action:#selector(NSApplication.terminate), keyEquivalent: "q")
//    }
//
//    func buildWnd() {
//
//        let _wndW : CGFloat = 400
//        let _wndH : CGFloat = 300
//
//        window = NSWindow(contentRect:NSMakeRect(0,0,_wndW,_wndH),styleMask:[.titled, .closable, .miniaturizable, .resizable], backing:.buffered, defer:false)
//        window.center()
//        window.title = "Swift Test Window"
//        window.makeKeyAndOrderFront(window)
//
//        // **** Button **** //
//        let myBtn = NSButton (frame:NSMakeRect( 100, 100, 175, 30 ))
//        myBtn.bezelStyle = .rounded
//        myBtn.autoresizingMask = [.maxXMargin,.minYMargin]
//        myBtn.title = "Build Second Window"
//        myBtn.action = #selector(self.myBtnAction(_:))
//        window.contentView!.addSubview (myBtn)
//
//        // **** Quit btn **** //
//        let quitBtn = NSButton (frame:NSMakeRect( _wndW - 50, 10, 40, 40 ))
//        quitBtn.bezelStyle = .circular
//        quitBtn.autoresizingMask = [.minXMargin,.maxYMargin]
//        quitBtn.title = "Q"
//        quitBtn.action = #selector(NSApplication.terminate)
//        window.contentView!.addSubview(quitBtn)
//    }
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        buildMenu()
//        buildWnd()
//    }
//
//    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//        return true
//    }
//}
