//
//  GUIBody.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import MetalKit

class GUIBody: Body {
    static let maxRectCount = 32
    static let maxLabelCount = 32
    
    var userInteractive = true
    var backgroundColor: SIMD4<UInt8> = .zero
    var alpha: Float = 1
    var views: [GUIView] { didSet { updatePointersIfNeeded() } }
    
    private var rectsPointer: UnsafeMutableRawPointer?
    private var rectCount: Int = 0
    private var labelsPointer: UnsafeMutableRawPointer?
    private var labelCount: Int = 0
    
    private var textTextureData = [GUIRenderData.TextRenderData?]()
    
    var renderData: GUIRenderData? {
        updatePointersIfNeeded()
        
        return GUIRenderData(alpha: alpha,
                             textTexturesData: textTextureData,
                             rectCount: rectCount,
                             rects: rectsPointer,
                             labelCount: labelCount,
                             labels: labelsPointer)
    }
    
    init(views: [GUIView] = [], backgroundColor: SIMD4<UInt8> = .init(1, 1, 1, 0)) {
        self.backgroundColor = backgroundColor
        self.views = views
        self.rectsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<GUIRenderData.RectModel>.stride * Self.maxRectCount,
                                                               alignment: MemoryLayout<GUIRenderData.RectModel>.alignment)
        self.labelsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<GUIRenderData.LabelModel>.stride * Self.maxLabelCount,
                                                              alignment: MemoryLayout<GUIRenderData.LabelModel>.alignment)
    }
    
    private func updatePointersIfNeeded() {
        // Set texture index here
        var newTextTextureData = [GUIRenderData.TextRenderData]()
        
        var rects = [GUIRenderData.RectModel]()
        var labels = [GUIRenderData.LabelModel]()
        
        let allRenderData = views.map { $0.makeRenderData() }
        
        allRenderData.forEach { rectsRenderData, labelsRenderData in
            rects.append(contentsOf: rectsRenderData)
            for (labelRenderData, texture) in labelsRenderData {
                var labelRenderData = labelRenderData
                labelRenderData.textTextureIndex = Int32(newTextTextureData.count)
                labels.append(labelRenderData)
                newTextTextureData.append(texture)
            }
        }
        
        rectsPointer?.copyMemory(from: &rects, byteCount: MemoryLayout<GUIRenderData.RectModel>.stride * rects.count)
        labelsPointer?.copyMemory(from: &labels, byteCount: MemoryLayout<GUIRenderData.LabelModel>.stride * labels.count)
        rectCount = rects.count
        labelCount = labels.count
        textTextureData = newTextTextureData
    }
    
    func hitTest(pos: CGPoint) -> Bool {
        views.filter { $0.isInteractive }.first(where: { $0.frame.contains(pos) }) != nil
    }
    
    func onTouchDown(pos: CGPoint) {
        let _ = views.reversed().first(where: { $0.onTouchDown(pos: pos) })
    }
    
    func onTouchMove(pos: CGPoint) {
        let _ = views.reversed().first(where: { $0.onTouchMove(pos: pos) })
    }
    
    func onTouchUp(pos: CGPoint) {
        let _ = views.reversed().first(where: { $0.onTouchUp(pos: pos) })
    }
}
