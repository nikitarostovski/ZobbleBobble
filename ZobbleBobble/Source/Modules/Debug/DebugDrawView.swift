//
//  DebugDrawView.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 25.12.2021.
//

import UIKit

final class DebugDrawView: UIView {
    weak var terrain: Terrain? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        super.draw(rect)
        guard let terrain = terrain, let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setFillColor(UIColor.cyan.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1)
        
        // Core
        if let core = terrain.core {
            drawChunk(core, at: context)
        }
        
        // Chunks
        for chunk in terrain.chunks {
            drawChunk(chunk, at: context)
        }
    }
    
    private func drawChunk(_ chunk: Chunk, at context: CGContext) {
        let scale = 2 * Const.screenHalfSize / bounds.width
        let xShift = bounds.width / 2
        let yShift = bounds.height / 2
        
        let polygon = chunk.polygon.map {
            CGPoint(x: ($0.x + chunk.position.x) * scale + xShift,
                    y: ($0.y + chunk.position.y) * scale + yShift)
        }
        
        for (i, p) in polygon.enumerated() {
            if i == 0 {
                context.move(to: p)
            }
            else {
                context.addLine(to: p)
            }
        }
        if let first = polygon.first {
            context.addLine(to: first)
        }
        context.drawPath(using: .fillStroke)
    }
    
    func chunkAt(_ p: CGPoint) -> Chunk? {
        let scale = 2 * Const.screenHalfSize / bounds.width
        let xShift = bounds.width / 2
        let yShift = bounds.height / 2
        
        let p = CGPoint(x: (p.x - xShift) / scale,
                        y: (p.y - yShift) / scale)
        
        for c in terrain?.chunks ?? [] {
            if c.globalPolygon.contains(point: p) != 0 {
                return c
            }
        }
        
        return nil
    }
}
