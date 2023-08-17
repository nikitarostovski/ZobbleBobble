//
//  GUIView.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIView<RenderData> {
    var renderData: RenderData!
    
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
    var needsDisplay = true
    
    func makeRenderData() -> RenderData {
        fatalError("method must be overriden")
    }
    
    func makeTextData() -> GUIRenderData.TextRenderData? {
        nil
    }
    
    init(backgroundColor: SIMD4<UInt8>, frame: CGRect) {
        self.backgroundColor = backgroundColor
        self.frame = frame
    }
}

