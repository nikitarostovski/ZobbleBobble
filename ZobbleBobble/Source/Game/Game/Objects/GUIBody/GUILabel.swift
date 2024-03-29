//
//  GUILabel.swift
//  ZobbleBobble
//
//  Created by Rost on 17.08.2023.
//

import Foundation

class GUILabel: GUIView {
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
    
    private var labelRenderData: GUIRenderData.ViewModel?

    init(frame: CGRect = .zero, style: Style = .header, text: String? = nil, onLayout: LayoutClosure? = nil) {
        self.text = text
        self.textColor = style.textColor
        super.init(backgroundColor: style.backgroundColor, frame: frame, onLayout: onLayout)
    }

    override func makeRenderData() -> RenderData {
        if needsDisplay {
            labelRenderData = GUIRenderData.ViewModel(viewType: 1,
                                                      backgroundColor: backgroundColor,
                                                      textColor: textColor,
                                                      origin: SIMD2<Float>(Float(frame.origin.x),
                                                                           Float(frame.origin.y)),
                                                      size: SIMD2<Float>(Float(frame.size.width),
                                                                         Float(frame.size.height)))
        }
        var result = super.makeRenderData()
        var labels = RenderData()
        if let labelRenderData = labelRenderData, let textData = makeTextData() {
            labels.append((labelRenderData, textData))
        }
        result.append(contentsOf: labels)
        return result
    }
    
    func makeTextData() -> GUIRenderData.TextRenderData? {
        let data = GUIRenderData.TextRenderData(text: text)
        return data
    }
}

extension GUILabel {
    enum Style {
        case header
        case info
        
        var backgroundColor: SIMD4<UInt8> {
            .zero
        }
        
        var textColor: SIMD4<UInt8> {
            switch self {
            case .header: return Colors.GUI.Label.textHeader
            case .info: return Colors.GUI.Label.textInfo
            }
        }
    }
}
