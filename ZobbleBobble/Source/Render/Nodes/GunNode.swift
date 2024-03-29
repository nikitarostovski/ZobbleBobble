//
//  GunNode.swift
//  ZobbleBobble
//
//  Created by Rost on 24.08.2023.
//

import Foundation
import MetalKit

class GunNode: BaseNode<GunBody> {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var computeDrawGunPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_gun")!)
    }()
    
    let uniformsBufferProvider: BufferProvider
    let originBufferProvider: BufferProvider
    let sizeBufferProvider: BufferProvider
    
    var samplerState: MTLSamplerState?
    var finalTexture: MTLTexture?
    
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, renderSize: CGSize, body: GunBody?) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.originBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.sizeBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.renderSize = renderSize
        
        super.init()
        
        self.body = body
        self.device = device
        
        self.finalTexture = device?.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        self.samplerState = device?.nearestSampler
    }
    
    override func render(commandBuffer: MTLCommandBuffer, cameraScale: Float, camera: SIMD2<Float>) -> MTLTexture? {
        guard let renderData = body?.renderData,
              let computeDrawGunPipelineState = computeDrawGunPipelineState,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return nil
        }
        
        var uniforms = Uniforms(cameraScale: cameraScale, camera: camera)
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = originBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let originBuffer = originBufferProvider.nextUniformsBuffer(data: renderData.originPointer, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = sizeBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let sizeBuffer = sizeBufferProvider.nextUniformsBuffer(data: renderData.sizePointer, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.originBufferProvider.avaliableResourcesSemaphore.signal()
            self.sizeBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        computeEncoder.setComputePipelineState(computeDrawGunPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(originBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(sizeBuffer, offset: 0, index: 2)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeDrawGunPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
