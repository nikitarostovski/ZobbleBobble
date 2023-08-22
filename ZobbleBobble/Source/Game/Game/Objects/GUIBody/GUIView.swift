//
//  GUIView.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIView {
    typealias RenderData = ([GUIRenderData.RectModel], [(GUIRenderData.LabelModel, GUIRenderData.TextRenderData)])
    typealias LayoutClosure = (GUIView) -> CGRect
    
    var isInteractive = false
    var needsDisplay = true
    
    var onLayout: LayoutClosure {
        didSet { needsDisplay = true }
    }
    
    
    var subviews: [GUIView] {
        didSet { needsDisplay = true }
    }
    
    var backgroundColor: SIMD4<UInt8> {
        didSet {
            if oldValue != backgroundColor {
                needsDisplay = true
            }
        }
    }
    
    /// View's frame in [0...1] coodinates for both axis
    var frame: CGRect {
        didSet {
            if oldValue != frame {
                needsDisplay = true
            }
        }
    }
    
    /// Render data for background color rect
    private var rectRenderData: GUIRenderData.RectModel?
    
    init(backgroundColor: SIMD4<UInt8> = .zero, frame: CGRect = .zero, subviews: [GUIView] = [], onLayout: LayoutClosure? = nil) {
        self.backgroundColor = backgroundColor
        self.frame = frame
        self.subviews = subviews
        self.onLayout = onLayout ?? { _ in .zero }
    }
    
    func layout() {
        frame = onLayout(self)
        subviews.forEach { $0.layout() }
    }
    
    func makeSubviewsRenderData() -> RenderData {
        return subviews.reduce(RenderData([], []), {
            var renderData = $1.makeRenderData()
            
            let rectsRenderData = renderData.0.map {
                var data = $0;
                data.origin.x += Float(frame.origin.x)
                data.origin.y += Float(frame.origin.y)
                return data;
            }
            let labelsRenderData = renderData.1.map {
                var data = $0;
                data.0.origin.x += Float(frame.origin.x)
                data.0.origin.y += Float(frame.origin.y)
                return data;
            }
            renderData.0 = rectsRenderData
            renderData.1 = labelsRenderData
            
            return RenderData($0.0 + rectsRenderData, $0.1 + labelsRenderData)
        })
    }
    
    func makeRenderData() -> RenderData {
        if needsDisplay, backgroundColor.w > 0 {
            let origin = SIMD2<Float>(Float(frame.origin.x), Float(frame.origin.y))
            let size = SIMD2<Float>(Float(frame.size.width), Float(frame.size.height))
            rectRenderData = .init(backgroundColor: backgroundColor, origin: origin, size: size)
        }
        var result = makeSubviewsRenderData()
        result.0 += [rectRenderData].compactMap { $0 }
        return result
    }
    
    func onTouchDown(pos: CGPoint) -> Bool { isInteractive }
    func onTouchMove(pos: CGPoint) -> Bool { isInteractive }
    func onTouchUp(pos: CGPoint) -> Bool { isInteractive }
}
