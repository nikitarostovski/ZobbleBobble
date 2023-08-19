//
//  main.swift
//  ZobbleBobble
//
//  Created by Rost on 19.08.2023.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func buildMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit", action:#selector(NSApplication.terminate), keyEquivalent: "q")
    }
    
    func buildWnd() {
        let height = Settings.Camera.sceneHeight
        let width = height * 0.7
        
        let controller = GameViewController()
        window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.backingType = .buffered
        window.title = "Game"
        
        var rect = window.contentRect(forFrameRect: window.frame)
        rect.size = .init(width: width, height: height)
        let frame = window.frameRect(forContentRect: rect)
        window.setFrame(frame, display: false)
        window.center()
        
        window.makeKey()
        window.orderFrontRegardless()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWnd()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.delegate = appDelegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps:true)
app.run()
