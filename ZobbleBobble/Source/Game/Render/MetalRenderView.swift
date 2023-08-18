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
    
    var cameraX: Float { get }
    var cameraY: Float { get }
    var cameraScale: Float { get }
}

protocol RenderViewDelegate: AnyObject {
    func rendererSizeDidChange(size: CGSize)
    func updateRenderData(time: TimeInterval)
}

final class MetalRenderView: MTKView {
    var renderer: Renderer?
    
    init(delegate: RenderViewDelegate?, dataSource: RenderViewDataSource?) {
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: .zero, device: device)
        self.renderer = Renderer(device: device, view: self, delegate: delegate, dataSource: dataSource)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
