//
//  MetalRenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

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
#if os(iOS)
        let device = MTLCreateSystemDefaultDevice()!
#elseif os(macOS)
        let device: MTLDevice
        
        let devices = MTLCopyAllDevices()
        if let discrete = devices.first(where: { !$0.isLowPower && !$0.isRemovable }) {
            device = discrete
        } else {
            device = MTLCreateSystemDefaultDevice()!
        }
#endif
        super.init(frame: .zero, device: device)
        colorPixelFormat = .bgra8Unorm
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetRenderer(delegate: RenderViewDelegate?, dataSource: RenderViewDataSource?, renderSize: CGSize) {
        renderer = Renderer(view: self, delegate: delegate, dataSource: dataSource, renderSize: renderSize)
    }
}
