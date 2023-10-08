//
//  TerrainNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.09.2023.
//

import MetalKit
import MetalPerformanceShaders
import ZobblePhysics

class TerrainNode: BaseNode<LiquidBody> {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var drawPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "draw_terrain")!)
    }()
    
    private lazy var clearPipelineState: MTLComputePipelineState? = {
        try! device!.makeComputePipelineState(function: device!.makeDefaultLibrary()!.makeFunction(name: "clear_terrain")!)
    }()
    
    let particleBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    
    var finalTexture: MTLTexture?
    
    let renderSize: CGSize
    
    init?(_ device: MTLDevice?, renderSize: CGSize, body: LiquidBody?) {
        self.particleBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<ZobblePhysics.ZobbleBody>.stride * Settings.Physics.maxParticleCount)
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        
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
        
        let particles = renderData.particles
        let pointCount = renderData.count
        
        var uniforms = Uniforms(cameraScale: cameraScale / renderData.scale, camera: camera)

        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)

        _ = particleBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let particleBuffer = particleBufferProvider.nextUniformsBuffer(data: particles,
                                                                       length: MemoryLayout<ZobblePhysics.ZobbleBody>.stride * pointCount)
        commandBuffer.addCompletedHandler { _ in
            self.particleBufferProvider.avaliableResourcesSemaphore.signal()
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
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
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 1)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawPipelineState, width: pointCount, height: 1)

        computeEncoder.endEncoding()
        return finalTexture
    }
}
