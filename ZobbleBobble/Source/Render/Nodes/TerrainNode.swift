//
//  TerrainNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.09.2023.
//

import MetalKit
import MetalPerformanceShaders

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
    
    let positionBufferProvider: BufferProvider
    let velocityBufferProvider: BufferProvider
    let colorBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    
    var finalTexture: MTLTexture?
    
    let renderSize: CGSize
    
    init?(_ device: MTLDevice?, renderSize: CGSize, body: LiquidBody?) {
        self.positionBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.Physics.maxParticleCount)
        self.velocityBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.Physics.maxParticleCount)
        self.colorBufferProvider = BufferProvider(device: device,
                                                  inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                  bufferSize: MemoryLayout<SIMD4<UInt8>>.stride * Settings.Physics.maxParticleCount)
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
        
        
        
        let vertices = renderData.liquidPositions
        let velocities = renderData.liquidVelocities
        let colors = renderData.liquidColors

        let pointCount = renderData.liquidCount
        
        var uniforms = Uniforms(cameraScale: cameraScale / renderData.scale, camera: camera)

        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)

        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: vertices,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * pointCount)

        _ = velocityBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let velocityBuffer = velocityBufferProvider.nextUniformsBuffer(data: velocities,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * pointCount)

        _ = colorBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let colorBuffer = colorBufferProvider.nextUniformsBuffer(data: colors,
                                                                 length: MemoryLayout<SIMD4<UInt8>>.stride * pointCount)

        commandBuffer.addCompletedHandler { _ in
            self.positionBufferProvider.avaliableResourcesSemaphore.signal()
            self.velocityBufferProvider.avaliableResourcesSemaphore.signal()
            self.colorBufferProvider.avaliableResourcesSemaphore.signal()
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
        computeEncoder.setBuffer(positionBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(velocityBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(colorBuffer, offset: 0, index: 3)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: drawPipelineState, width: pointCount, height: 1)

        computeEncoder.endEncoding()
        return finalTexture
    }
}
