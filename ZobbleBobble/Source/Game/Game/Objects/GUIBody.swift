//
//  GUIBody.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import MetalKit

class GUIBody: Body {
    static let maxButtonCount = 32
    static let maxLabelCount = 32
    
    var userInteractive = true
    var backgroundColor: SIMD4<UInt8> = .zero
    var alpha: Float = 1
    
    private var buttons: [GUIButton]
    private var labels: [GUILabel]
    
    private var buttonsPointer: UnsafeMutableRawPointer?
    private var labelsPointer: UnsafeMutableRawPointer?
    private var textTextureData = [GUIRenderData.TextRenderData?]()
    
    var renderData: GUIRenderData? {
        updateButtonsPointerIfNeeded()
        return GUIRenderData(alpha: alpha,
                             textTexturesData: textTextureData,
                             buttonCount: buttons.count,
                             buttons: buttonsPointer,
                             labelCount: labels.count,
                             labels: labelsPointer)
    }
    
    init(buttons: [GUIButton] = [], labels: [GUILabel] = []) {
        self.buttons = buttons
        self.labels = labels
        
        self.buttonsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<GUIRenderData.ButtonModel>.stride * Self.maxButtonCount,
                                                               alignment: MemoryLayout<GUIRenderData.ButtonModel>.alignment)
        self.labelsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<GUIRenderData.LabelModel>.stride * Self.maxLabelCount,
                                                              alignment: MemoryLayout<GUIRenderData.LabelModel>.alignment)
    }
    
    private func updateButtonsPointerIfNeeded() {
        // Set texture index here
        var newTextTextureData = [GUIRenderData.TextRenderData?]()
        
        var buttonsRenderData = buttons.map {
            var data = $0.makeRenderData()
            data.textTextureIndex = Int32(newTextTextureData.count)
            newTextTextureData.append($0.makeTextData())
            return data
        }
        var labelsRenderData = labels.map {
            var data = $0.makeRenderData()
            data.textTextureIndex = Int32(newTextTextureData.count)
            newTextTextureData.append($0.makeTextData())
            return data
        }
        buttonsPointer?.copyMemory(from: &buttonsRenderData, byteCount: MemoryLayout<GUIRenderData.ButtonModel>.stride * buttons.count)
        labelsPointer?.copyMemory(from: &labelsRenderData, byteCount: MemoryLayout<GUIRenderData.LabelModel>.stride * labels.count)
        textTextureData = newTextTextureData
    }
    
    
    func onTouchDown(pos: CGPoint) {
        let _ = buttons.reversed().first(where: { $0.onTouchDown(pos: pos) })
    }
    
    func onTouchMove(pos: CGPoint) {
        let _ = buttons.reversed().first(where: { $0.onTouchMove(pos: pos) })
    }
    
    func onTouchUp(pos: CGPoint) {
        let _ = buttons.reversed().first(where: { $0.onTouchUp(pos: pos) })
    }
}
