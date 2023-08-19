//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import UIKit
import MetalKit

protocol RenderViewDataSource: AnyObject {
    var visibleBodies: [any Body] { get }
    var backgroundColor: SIMD4<UInt8> { get }
    
    var cameraX: Float { get }
    var cameraY: Float { get }
    var cameraScale: Float { get }
}

protocol RenderViewDelegate: AnyObject {
    func rendererSizeDidChange(size: CGSize)
    func updateRenderData(time: TimeInterval)
}

final class MetalRenderView: MTKView {
    private var renderer: Renderer?
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: .zero, device: device)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetRenderer(delegate: RenderViewDelegate?, dataSource: RenderViewDataSource?, renderSize: CGSize) {
        renderer = Renderer(view: self, delegate: delegate, dataSource: dataSource, renderSize: renderSize)
    }
}
