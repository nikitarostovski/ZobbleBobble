//
//  CoreNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

import MetalKit
import MetalPerformanceShaders

class CoreNode: BaseNode<CoreBody> {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var drawPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "draw_core")!)
    }()
    
    private lazy var clearPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "clear_core")!)
    }()
    
    let uniformsBufferProvider: BufferProvider
    let coreBufferProvider: BufferProvider
    let timeBufferProvider: BufferProvider
    
    var finalTexture: MTLTexture?
    
    let renderSize: CGSize
    
    init?(_ device: MTLDevice?, renderSize: CGSize, body: CoreBody?) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.coreBufferProvider = BufferProvider(device: device,
                                                 inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                 bufferSize: MemoryLayout<CoreRenderData.Core>.stride)
        self.timeBufferProvider = BufferProvider(device: device,
                                                 inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                 bufferSize: MemoryLayout<Float>.stride)
        
        self.renderSize = renderSize
        
        super.init()
        
        self.body = body
        self.device = device
        self.finalTexture = device?.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
    }
    
    override func render(commandBuffer: MTLCommandBuffer,
                         cameraScale: Float32,
                         camera: SIMD2<Float32>) -> MTLTexture? {
        
        guard let renderData = body?.renderData else { return nil }
        
        var uniforms = Uniforms(cameraScale: cameraScale / renderData.scale, camera: camera)
        var core = renderData.core
        
        _ = coreBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let coreBuffer = coreBufferProvider.nextUniformsBuffer(data: &core, length: MemoryLayout<CoreRenderData.Core>.stride)
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)

        var time = Float(CACurrentMediaTime())
        _ = timeBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let timeBuffer = timeBufferProvider.nextUniformsBuffer(data: &time, length: MemoryLayout<Float>.stride)

        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.timeBufferProvider.avaliableResourcesSemaphore.signal()
            self.coreBufferProvider.avaliableResourcesSemaphore.signal()
        }

        guard let drawPipelineState = drawPipelineState, let clearPipelineState = clearPipelineState else {
            return nil
        }
        
        guard let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return finalTexture
        }

        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: clearPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(drawPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(coreBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(timeBuffer, offset: 0, index: 2)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawPipelineState, width: finalTexture.width, height: finalTexture.height)

        computeEncoder.endEncoding()
        return finalTexture
    }
}
