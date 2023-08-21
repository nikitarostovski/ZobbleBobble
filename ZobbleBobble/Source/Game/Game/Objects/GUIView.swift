//
//  GUIView.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIView {
    typealias RenderData = ([GUIRenderData.RectModel], [(GUIRenderData.LabelModel, GUIRenderData.TextRenderData)])
    
    var isInteractive = false
    var needsDisplay = true
    
    var backgroundColor: SIMD4<UInt8> {
        didSet {
            if oldValue != backgroundColor {
                needsDisplay = true
            }
        }
    }
    
    var frame: CGRect {
        didSet {
            if oldValue != frame {
                needsDisplay = true
            }
        }
    }
    
    func makeRenderData() -> RenderData {
        fatalError("method must be overriden")
    }
    
    init(backgroundColor: SIMD4<UInt8>, frame: CGRect) {
        self.backgroundColor = backgroundColor
        self.frame = frame
    }
    
    func onTouchDown(pos: CGPoint) -> Bool { false }
    func onTouchMove(pos: CGPoint) -> Bool { false }
    func onTouchUp(pos: CGPoint) -> Bool { false }
}
