//
//  RenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 20.12.2022.
//

import UIKit

struct PolygonRenderData {
    let polygon: [CGPoint]
}

struct LiquidRenderData {
    let positions: [CGPoint]
}

final class RenderView: UIView {
    var particleRadius: CGFloat = 0
    
    var polygonRenderData = [PolygonRenderData]() { didSet { setNeedsDisplay() } }
    var liquidRenderData = [LiquidRenderData]() { didSet { setNeedsDisplay() } }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        backgroundColor = .black
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let offsetX = frame.width / 2
        let offsetY = frame.height / 2
        
        for polygon in polygonRenderData {
            var polygon = polygon.polygon.map { CGPoint(x: $0.x + offsetX, y: $0.y + offsetY) }
            guard polygon.count > 2 else { continue }
            
            polygon.append(polygon.first!)
            
            context.setFillColor(UIColor.yellow.withAlphaComponent(1.25).cgColor)
            context.addLines(between: polygon)
            context.fillPath(using: .evenOdd)
            
            context.setLineWidth(2)
            context.setStrokeColor(UIColor.yellow.withAlphaComponent(1).cgColor)
            context.strokePath()
            
        }
        
//        context.setStrokeColor(UIColor.red.cgColor)
//        context.setFillColor(UIColor.red.cgColor)
        for liquid in liquidRenderData {
            for point in liquid.positions {
                let circleRect = CGRect(x: point.x - particleRadius + offsetX,
                                        y: point.y - particleRadius + offsetY,
                                        width: particleRadius,
                                        height: particleRadius)
                
                context.strokeEllipse(in: circleRect)
                context.fillEllipse(in: circleRect)
            }
        }
    }
}
