//
//  DebugDrawView.swift
//  LevelDesign
//
//  Created by Rost on 17.03.2021.
//

import Cocoa

protocol DebugDrawViewInteractionDelegate: class {
    
    func didTap(at point: CGPoint)
}

class DebugDrawView: NSView {
    
    public weak var delegate: DebugDrawViewInteractionDelegate?
    
    private weak var level: Level? {
        didSet {
            update()
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
    
    public func update() {
        needsDisplay = true
        displayIfNeeded()
    }
    
    private func postInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let pos = convert(event.locationInWindow, from: nil)
        
        delegate?.didTap(at: CGPoint(x: pos.x / bounds.width, y: pos.y / bounds.height))
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let level = level, let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Polygons
        
        context.setStrokeColor(CGColor.black)
        context.setLineWidth(1)
        
        for cell in level.cells {
            context.setFillColor(NSColor(red: cell.color.r, green: cell.color.g, blue: cell.color.b, alpha: 0.5).cgColor)
            let p = cell.polygon
            guard p.count > 2 else { continue }
            let cp = p + [p.first!]
            let np = cp.map { CGPoint(x: $0.x * bounds.width / level.width,
                                      y: $0.y * bounds.height / level.height) }
            context.beginPath()
            
            context.addLines(between: np)
            
            context.drawPath(using: .fillStroke)
        }
        
        // Player
        
        if let pos = level.playerPosition {
            context.setStrokeColor(NSColor.blue.cgColor)
            context.setLineWidth(1)
            context.setFillColor(NSColor.cyan.withAlphaComponent(0.5).cgColor)
            
            context.beginPath()
            
            let size: CGFloat = 20
            context.addEllipse(in: CGRect(x: pos.x * bounds.width / level.width - size / 2,
                                          y: pos.y * bounds.height / level.height - size / 2,
                                          width: size,
                                          height: size))
            
            context.drawPath(using: .fillStroke)
        }
        
        // Exit
        
        if let pos = level.exitPosition {
            context.setStrokeColor(NSColor.red.cgColor)
            context.setLineWidth(1)
            context.setFillColor(NSColor.yellow.withAlphaComponent(0.5).cgColor)
            
            context.beginPath()
            
            let size: CGFloat = 20
            context.addEllipse(in: CGRect(x: pos.x * bounds.width / level.width - size / 2,
                                          y: pos.y * bounds.height / level.height - size / 2,
                                          width: size,
                                          height: size))
            
            context.drawPath(using: .fillStroke)
        }
        
        // Checkpoints
        
        if level.checkpoints.count > 0 {
            context.setStrokeColor(NSColor.green.cgColor)
            context.setLineWidth(2)
            context.setFillColor(NSColor.green.withAlphaComponent(0.5).cgColor)
            
            let size: CGFloat = 10
            
            for pos in level.checkpoints {
                context.beginPath()
                
                context.addEllipse(in: CGRect(x: pos.x * bounds.width / level.width - size / 2,
                                              y: pos.y * bounds.height / level.height - size / 2,
                                              width: size,
                                              height: size))
                
                context.drawPath(using: .fillStroke)
            }
        }
    }
}
