//
//  GUIButton.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

class GUIButton: GUIView {
    private var normalBackgroundColor: SIMD4<UInt8>
    private var highlightedBackgroundColor: SIMD4<UInt8>
    private var normalTextColor: SIMD4<UInt8>
    private var highlightedTextColor: SIMD4<UInt8>
    
    private var isTouchResponder = false
    
    var tapAction: (() -> Void)?
    
    var textInsets: CGSize {
        didSet {
            if oldValue != textInsets {
                needsDisplay = true
            }
        }
    }
    
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
    
    private var labelRenderData: GUIRenderData.ViewModel?
    
    init(frame: CGRect = .zero, style: Style = .primary, title: String?, tapAction: (() -> Void)? = nil, textInsets: CGSize = .zero, onLayout: LayoutClosure? = nil) {
        self.tapAction = tapAction
        self.textInsets = textInsets
        self.text = title
        self.normalTextColor = style.titleColorNormal
        self.highlightedTextColor = style.titleColorHighlighted
        self.textColor = style.titleColorNormal
        
        self.normalBackgroundColor = style.backgroundColorNormal
        self.highlightedBackgroundColor = style.backgroundColorHighlighted
        
        super.init(backgroundColor: style.backgroundColorNormal, frame: frame, onLayout: onLayout)
        
        isInteractive = true
    }
    
    override func makeRenderData() -> RenderData {
        if needsDisplay {
            var textOrigin = SIMD2<Float>(Float(frame.origin.x), Float(frame.origin.y))
            textOrigin.x += Float(textInsets.width)
            textOrigin.y += Float(textInsets.height)
            var textSize = SIMD2<Float>(Float(frame.size.width), Float(frame.size.height))
            textSize.x -= 2 * Float(textInsets.width)
            textSize.y -= 2 * Float(textInsets.height)
            
            labelRenderData = .init(viewType: GUIRenderData.ViewModel.viewTypeText, backgroundColor: .zero, textColor: textColor, origin: textOrigin, size: textSize)
        }
        var result = super.makeRenderData()
        var labels = RenderData()
        if let labelRenderData = labelRenderData, let textData = makeTextData() {
            labels.append((labelRenderData, textData))
        }
        result.append(contentsOf: labels)
        return result.reversed()
    }
    
    func makeTextData() -> GUIRenderData.TextRenderData? {
        let data = GUIRenderData.TextRenderData(text: text)
        return data
    }
    
    override func onTouchDown(pos: CGPoint) -> Bool {
        guard frame.contains(pos) else {
            isHighlighted = false
            return false
        }
        isTouchResponder = true
        isHighlighted = true
        return true
    }
    
    override func onTouchMove(pos: CGPoint) -> Bool {
        guard frame.contains(pos) else {
            isHighlighted = false
            return false
        }
        isHighlighted = true
        return true
    }
    
    override func onTouchUp(pos: CGPoint) -> Bool {
        isHighlighted = false
        guard isTouchResponder else { return false }
        
        isTouchResponder = false
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
