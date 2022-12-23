//
//  DebugRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit

final class DebugRenderView: UIView, RenderView {
    var renderData = [RenderData]()
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        backgroundColor = .black
    }
    
    func setRenderData(_ renderData: [RenderData]) {
        self.renderData = renderData
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let offsetX = frame.width / 2
        let offsetY = frame.height / 2
        
        
        for data in renderData {
            switch data {
            case .polygon(let polygon, let color):
                let c = UIColor(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
                context.setStrokeColor(c.cgColor)
                context.setFillColor(c.cgColor)
                context.addLines(between: polygon)
                context.fillPath(using: .evenOdd)
            case .circle(let position, let radius, let color):
                let c = UIColor(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: CGFloat(color.w))
                context.setStrokeColor(c.cgColor)
                context.setFillColor(c.cgColor)
                let circleRect = CGRect(x: position.x - radius + offsetX,
                                        y: position.y - radius + offsetY,
                                        width: 2 * radius,
                                        height: 2 * radius)
                
                context.strokeEllipse(in: circleRect)
                context.fillEllipse(in: circleRect)
            case .liquid(let count, let radius, let positions, let colors):break
//                for i in 0 ..< count {
//                    let color = UIColor(red: CGFloat(colors[i].x), green: CGFloat(colors[i].y), blue: CGFloat(colors[i].z), alpha: CGFloat(colors[i].w))
//
//                    context.setStrokeColor(color.cgColor)
//                    context.setFillColor(color.cgColor)
//                    let circleRect = CGRect(x: CGFloat(positions[i].x) - radius + offsetX,
//                                            y: CGFloat(positions[i].y) - radius + offsetY,
//                                            width: 2 * radius,
//                                            height: 2 * radius)
//
//                    context.strokeEllipse(in: circleRect)
//                    context.fillEllipse(in: circleRect)
//                }
            }
        }
        
//        for polygon in polygonRenderData {
//            let circleRect = CGRect(x: polygon.position.x - polygon.radius + offsetX,
//                                    y: polygon.position.y - polygon.radius + offsetY,
//                                    width: 2 * polygon.radius,
//                                    height: 2 * polygon.radius)
//            
//            context.strokeEllipse(in: circleRect)
//            context.fillEllipse(in: circleRect)
//            var polygon = polygon.polygon.map { CGPoint(x: $0.x + offsetX, y: $0.y + offsetY) }
//            guard polygon.count > 2 else { continue }
//
//            polygon.append(polygon.first!)
//
//            context.setFillColor(UIColor.yellow.withAlphaComponent(1.25).cgColor)
//            context.addLines(between: polygon)
//            context.fillPath(using: .evenOdd)
//
//            context.setLineWidth(2)
//            context.setStrokeColor(UIColor.yellow.withAlphaComponent(1).cgColor)
//            context.strokePath()
            
//        }
//        context.setStrokeColor(UIColor.red.cgColor)
//        context.setFillColor(UIColor.red.cgColor)
//        for liquid in liquidRenderData {
//            for point in liquid.positions {
//                let circleRect = CGRect(x: point.x - particleRadius + offsetX,
//                                        y: point.y - particleRadius + offsetY,
//                                        width: 2 * particleRadius,
//                                        height: 2 * particleRadius)
//
//                context.strokeEllipse(in: circleRect)
//                context.fillEllipse(in: circleRect)
//            }
//        }
    }
}
