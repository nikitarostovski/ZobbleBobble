//
//  DebugDrawView.swift
//  LevelDesign
//
//  Created by Rost on 17.03.2021.
//

import Cocoa

class DebugDrawView: NSView {
    
    private weak var level: Level? {
        didSet {
            self.needsDisplay = true
            self.displayIfNeeded()
        }
    }
    
    func draw(level: Level) {
        self.level = level
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        postInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        postInit()
    }
    
    private func postInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let level = level, let context = NSGraphicsContext.current?.cgContext else { return }
        
        
        for p in level.polygons {
            guard p.count > 2 else { continue }
            let cp = p + [p.first!]
            let np = cp.map { CGPoint(x: $0.x * bounds.width / level.width,
                                      y: $0.y * bounds.height / level.height) }
            context.beginPath()
            
            context.addLines(between: np)
            
            context.strokePath()
//            context.closePath()
        }
    }
}
