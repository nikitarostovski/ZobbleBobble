//
//  GUIButton.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

class GUIButton: GUIView<GUIRenderData.ButtonModel> {
    private var normalBackgroundColor: SIMD4<UInt8>
    private var highlightedBackgroundColor: SIMD4<UInt8>
    private var normalTextColor: SIMD4<UInt8>
    private var highlightedTextColor: SIMD4<UInt8>
    
    var tapAction: (() -> Void)?
    
    var textColor: SIMD4<UInt8> {
        didSet {
            if oldValue != textColor {
                needsDisplay = true
            }
        }
    }
    
    var isHighlighted: Bool = false {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
        }
    }
    
    var text: String? {
        didSet {
            if text != oldValue {
                needsDisplay = true
            }
        }
    }
    
    init(frame: CGRect = .zero, style: Style = .primary, title: String?, tapAction: (() -> Void)? = nil) {
        self.tapAction = tapAction
        self.text = title
        self.normalTextColor = style.titleColorNormal
        self.highlightedTextColor = style.titleColorHighlighted
        self.textColor = style.titleColorNormal
        
        self.normalBackgroundColor = style.backgroundColorNormal
        self.highlightedBackgroundColor = style.backgroundColorHighlighted
        
        super.init(backgroundColor: style.backgroundColorNormal, frame: frame)
    }
    
    override func makeRenderData() -> GUIRenderData.ButtonModel {
        if needsDisplay {
            renderData = GUIRenderData.ButtonModel(backgroundColor: backgroundColor,
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
    
    func onTouchDown(pos: CGPoint) -> Bool {
        guard frame.contains(pos) else {
            isHighlighted = false
            return false
        }
        isHighlighted = true
        return true
    }
    
    func onTouchMove(pos: CGPoint) -> Bool {
        guard frame.contains(pos) else {
            isHighlighted = false
            return false
        }
        isHighlighted = true
        return true
    }
    
    func onTouchUp(pos: CGPoint) -> Bool {
        isHighlighted = false
        if frame.contains(pos) {
            tapAction?()
        }
        return frame.contains(pos)
    }
}

extension GUIButton {
    enum Style {
        case primary
        case secondary
        case utility
        
        var backgroundColorNormal: SIMD4<UInt8> {
            switch self {
            case .primary: return Colors.GUI.Button.backgroundPrimaryNormal
            case .secondary: return Colors.GUI.Button.backgroundSecondaryNormal
            case .utility: return Colors.GUI.Button.backgroundUtilityNormal
            }
        }
        
        var backgroundColorHighlighted: SIMD4<UInt8> {
            switch self {
            case .primary: return Colors.GUI.Button.backgroundPrimaryHighlighted
            case .secondary: return Colors.GUI.Button.backgroundSecondaryHighlighted
            case .utility: return Colors.GUI.Button.backgroundUtilityHighlighted
            }
        }
        
        var titleColorNormal: SIMD4<UInt8> {
            Colors.GUI.Button.titleNormal
        }
        
        var titleColorHighlighted: SIMD4<UInt8> {
            Colors.GUI.Button.titleHighlighted
        }
    }
}
