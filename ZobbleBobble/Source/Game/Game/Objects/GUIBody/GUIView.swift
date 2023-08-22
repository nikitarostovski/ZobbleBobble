//
//  GUIView.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIView {
    typealias RenderData = ([GUIRenderData.RectModel], [(GUIRenderData.LabelModel, GUIRenderData.TextRenderData)])
    
    // TODO: subviews autolayout
//    struct GUIFrame: Equatable {
//        enum Value: Equatable {
//            /// absolute value in [0...1] range, where 1 is screen size for current axis
//            case absolute(Float)
//            /// percent value in [0...1] range, where 1 is parent view's frame value for current axis
//            case percent(Float, )
//
//            static func == (lhs: Value, rhs: Value) -> Bool {
//                switch (lhs, rhs) {
//                case (.absolute(let lv), .absolute(let rv)):
//                    return lv == rv
//                case (.percent(let lv), .percent(let rv)):
//                    return lv == rv
//                default:
//                    return false
//                }
//            }
//        }
//
//        let x: Value
//        let y: Value
//        let width: Value
//        let height: Value
//
//        static func == (lhs: GUIView.GUIFrame, rhs: GUIView.GUIFrame) -> Bool {
//            return lhs.x == rhs.x && lhs.y == rhs.y && lhs.width == rhs.width && lhs.height == rhs.height
//        }
//
//        static var zero: GUIFrame { GUIFrame(x: .absolute(0), y: .absolute(0), width: .absolute(0), height: .absolute(0)) }
//    }
    
    var isInteractive = false
    var needsDisplay = true
    
    var subviews: [GUIView] {
        didSet {
            needsDisplay = true
        }
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
    
    init(backgroundColor: SIMD4<UInt8> = .zero, frame: CGRect = .zero, subviews: [GUIView] = []) {
        self.backgroundColor = backgroundColor
        self.frame = frame
        self.subviews = subviews
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
