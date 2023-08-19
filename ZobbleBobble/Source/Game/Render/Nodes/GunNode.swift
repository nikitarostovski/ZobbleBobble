//
//  GunNode.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
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
    
    let computePassDescriptor = MTLComputePassDescriptor()
    
    let uniformsBufferProvider: BufferProvider
    let gunCenterBufferProvider: BufferProvider
    let renderCenterBufferProvider: BufferProvider
    let missleCenterBufferProvider: BufferProvider
    let gunRadiusBufferProvider: BufferProvider
    let notchRadiusBufferProvider: BufferProvider
    let materialsBufferProvider: BufferProvider
    let materialCountsBufferProvider: BufferProvider
    
    var samplerState: MTLSamplerState?
    var finalTexture: MTLTexture?
    
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, renderSize: CGSize, body: GunBody?) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.gunCenterBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.renderCenterBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.missleCenterBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                         bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.gunRadiusBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<Float32>.stride)
        self.notchRadiusBufferProvider = BufferProvider(device: device,
                                                        inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                        bufferSize: MemoryLayout<Float32>.stride)
        self.materialsBufferProvider = BufferProvider(device: device,
                                                      inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                      bufferSize: MemoryLayout<MaterialRenderData>.stride * Settings.Physics.maxMaterialCount)
        self.materialCountsBufferProvider = BufferProvider(device: device,
                                                           inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                           bufferSize: MemoryLayout<Int32>.stride)
        self.renderSize = renderSize
        
        super.init()
        
        self.body = body
        self.device = device
        
        self.finalTexture = device?.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        
        self.samplerState = device?.nearestSampler
    }
    
    override func render(commandBuffer: MTLCommandBuffer, cameraScale: Float, camera: SIMD2<Float>) -> MTLTexture? {
        guard let renderData = body?.renderData,
              renderData.materialCount > 0,
              let computeDrawGunPipelineState = computeDrawGunPipelineState,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)
        else {
            return nil
        }
        
        let position = renderData.positionPointer
        let renderCenter = renderData.renderCenterPointer
        let missleCenter = renderData.missleCenterPointer
        let radius = renderData.radiusPointer
        let missleRadius = renderData.missleRadiusPointer
        let materials = renderData.materialsPointer
        
        let defaultScale = Float(1)//Float(renderSize.width / screenSize.width)
        var uniforms = Uniforms(cameraScale: cameraScale * defaultScale, camera: camera)
        
        var materialCount = renderData.materialCount
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = gunCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let gunCenterBuffer = gunCenterBufferProvider.nextUniformsBuffer(data: position, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = renderCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let renderCenterBuffer = renderCenterBufferProvider.nextUniformsBuffer(data: renderCenter, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = missleCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let missleCenterBuffer = missleCenterBufferProvider.nextUniformsBuffer(data: missleCenter, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = gunRadiusBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let gunRadiusBuffer = gunRadiusBufferProvider.nextUniformsBuffer(data: radius, length: MemoryLayout<Float32>.stride)
        
        _ = notchRadiusBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let notchRadiusBuffer = notchRadiusBufferProvider.nextUniformsBuffer(data: missleRadius, length: MemoryLayout<Float32>.stride)
        
        _ = materialsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let materialsBuffer = materialsBufferProvider.nextUniformsBuffer(data: materials, length: MemoryLayout<MaterialRenderData>.stride * materialCount)
        
        _ = materialCountsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let materialCountBuffer = materialCountsBufferProvider.nextUniformsBuffer(data: &materialCount, length: MemoryLayout<Int32>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.gunCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.renderCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.missleCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.gunRadiusBufferProvider.avaliableResourcesSemaphore.signal()
            self.notchRadiusBufferProvider.avaliableResourcesSemaphore.signal()
            self.materialsBufferProvider.avaliableResourcesSemaphore.signal()
            self.materialCountsBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        clearTexture(texture: finalTexture, computeEncoder: computeEncoder)
        
        computeEncoder.setComputePipelineState(computeDrawGunPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(gunCenterBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(missleCenterBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(renderCenterBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(gunRadiusBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(notchRadiusBuffer, offset: 0, index: 5)
        computeEncoder.setBuffer(materialsBuffer, offset: 0, index: 6)
        computeEncoder.setBuffer(materialCountBuffer, offset: 0, index: 7)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeDrawGunPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
