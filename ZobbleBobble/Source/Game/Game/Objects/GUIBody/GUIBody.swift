//
//  GUIBody.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import MetalKit

class GUIBody: Body {
    static let maxViewCount = 96
    
    var userInteractive = true
    var backgroundColor: SIMD4<UInt8> = .zero
    var alpha: Float = 1
    var views: [GUIView] { didSet { updatePointersIfNeeded() } }
    
    private var needsDisplay = true
    
    private var viewsPointer: UnsafeMutableRawPointer?
    private var viewCount: Int = 0
    
    private var textTextureData = [GUIRenderData.TextRenderData?]()
    
    var renderData: GUIRenderData? {
        updatePointersIfNeeded()
        
        return GUIRenderData(alpha: alpha,
                             textTexturesData: textTextureData,
                             viewCount: viewCount,
                             views: viewsPointer)
    }
    
    init(views: [GUIView] = [], backgroundColor: SIMD4<UInt8> = .init(1, 1, 1, 0)) {
        self.backgroundColor = backgroundColor
        self.views = views
        self.viewsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<GUIRenderData.ViewModel>.stride * Self.maxViewCount,
                                                               alignment: MemoryLayout<GUIRenderData.ViewModel>.alignment)
    }
    
    private func updatePointersIfNeeded() {
        let needsDisplay = needsDisplay || views.reduce(into: false, { $0 = $0 || $1.needsDisplay })
        guard needsDisplay else { return }
        defer { self.needsDisplay = false }
        
        var newTextTextureData = [GUIRenderData.TextRenderData]()
        var newViewRenderData = [GUIRenderData.ViewModel]()
        
        let allRenderData = views.map { $0.makeRenderData() }
        
        // Set text texture index here
        allRenderData.forEach { renderData in
            for (viewData, texture) in renderData {
                var viewData = viewData
                if let texture = texture {
                    viewData.textTextureIndex = Int32(newTextTextureData.count)
                    newTextTextureData.append(texture)
                }
                newViewRenderData.append(viewData)
            }
        }
        
        viewsPointer?.copyMemory(from: &newViewRenderData, byteCount: MemoryLayout<GUIRenderData.ViewModel>.stride * newViewRenderData.count)
        viewCount = newViewRenderData.count
        textTextureData = newTextTextureData
    }
    
    func layout() {
        views.forEach { $0.layout() }
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
