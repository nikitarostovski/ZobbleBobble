//
//  GUILabel.swift
//  ZobbleBobble
//
//  Created by Rost on 17.08.2023.
//

import Foundation

class GUILabel: GUIView<GUIRenderData.LabelModel> {
    var textColor: SIMD4<UInt8> {
        didSet {
            if oldValue != textColor {
                needsDisplay = true
            }
        }
    }
    
    var text: String? {
        didSet {
            if text != oldValue {
                needsDisplay = true
            }
        }
    }

    init(frame: CGRect = .zero, style: Style = .header, text: String? = nil) {
        self.text = text
        self.textColor = style.textColor
        super.init(backgroundColor: style.backgroundColor, frame: frame)
    }

    override func makeRenderData() -> GUIRenderData.LabelModel {
        if needsDisplay {
            renderData = GUIRenderData.LabelModel(backgroundColor: backgroundColor,
                                                  textColor: textColor,
                                                  origin: SIMD2<Float>(Float(frame.origin.x),
                                                                       Float(frame.origin.y)),
                                                  size: SIMD2<Float>(Float(frame.size.width),
                                                                     Float(frame.size.height)))
        }
        needsDisplay = false
        return renderData
    }
    
    override func makeTextData() -> GUIRenderData.TextRenderData? {
        let data = GUIRenderData.TextRenderData(text: text)
        return data
    }
}

extension GUILabel {
    enum Style {
        case header
        
        var backgroundColor: SIMD4<UInt8> {
            switch self {
            case .header: return .zero
            }
        }
        
        var textColor: SIMD4<UInt8> {
            switch self {
            case .header: return Colors.GUI.Label.textHeader
            }
        }
    }
}
