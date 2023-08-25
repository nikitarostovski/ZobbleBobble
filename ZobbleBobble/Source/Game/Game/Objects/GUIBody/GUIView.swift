//
//  GUIView.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIView {
    typealias RenderData = [(GUIRenderData.ViewModel, GUIRenderData.TextRenderData?)]
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
    
    var bounds: CGRect {
        CGRect(origin: .zero, size: frame.size)
    }
    
    /// Render data for background color rect
    private var rectRenderData: GUIRenderData.ViewModel?
    
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
        return subviews.reduce(RenderData([]), {
            let renderData = $1.makeRenderData()
            let correctedData = renderData.map {
                var data = $0;
                data.0.origin.x += Float(frame.origin.x)
                data.0.origin.y += Float(frame.origin.y)
                return data;
            }
            return $0 + correctedData
        })
    }
    
    func makeRenderData() -> RenderData {
        if needsDisplay, backgroundColor.w > 0 {
            let origin = SIMD2<Float>(Float(frame.origin.x), Float(frame.origin.y))
            let size = SIMD2<Float>(Float(frame.size.width), Float(frame.size.height))
            rectRenderData = .init(viewType: 0,
                                   backgroundColor: backgroundColor,
                                   textColor: nil,
                                   origin: origin,
                                   size: size)
        }
        var result = makeSubviewsRenderData()
        result += [rectRenderData].compactMap { $0.map { ($0, nil) } }
        needsDisplay = false
        return result
    }
    
    func onTouchDown(pos: CGPoint) -> Bool { isInteractive }
    func onTouchMove(pos: CGPoint) -> Bool { isInteractive }
    func onTouchUp(pos: CGPoint) -> Bool { isInteractive }
}
