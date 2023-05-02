//
//  StarsMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 30.01.2023.
//

import MetalKit

class StarsMesh: BaseMesh {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var computeDrawStarPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_star")!)
    }()
    
    let computePassDescriptor = MTLComputePassDescriptor()
    
    let uniformsBufferProvider: BufferProvider
    let starCenterBufferProvider: BufferProvider
    let renderCenterBufferProvider: BufferProvider
    let missleCenterBufferProvider: BufferProvider
    let starRadiusBufferProvider: BufferProvider
    let notchRadiusBufferProvider: BufferProvider
    let materialsBufferProvider: BufferProvider
    let materialCountsBufferProvider: BufferProvider
    
    var samplerState: MTLSamplerState?
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.starCenterBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.inflightBufferCount,
                                                       bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.renderCenterBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.inflightBufferCount,
                                                         bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.missleCenterBufferProvider = BufferProvider(device: device,
                                                         inflightBuffersCount: Settings.inflightBufferCount,
                                                         bufferSize: MemoryLayout<SIMD2<Float32>>.stride)
        self.starRadiusBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.inflightBufferCount,
                                                       bufferSize: MemoryLayout<Float32>.stride)
        self.notchRadiusBufferProvider = BufferProvider(device: device,
                                                        inflightBuffersCount: Settings.inflightBufferCount,
                                                        bufferSize: MemoryLayout<Float32>.stride)
        self.materialsBufferProvider = BufferProvider(device: device,
                                                      inflightBuffersCount: Settings.inflightBufferCount,
                                                      bufferSize: MemoryLayout<StarMaterialData>.stride * Settings.maxMaterialCount)
        self.materialCountsBufferProvider = BufferProvider(device: device,
                                                           inflightBuffersCount: Settings.inflightBufferCount,
                                                           bufferSize: MemoryLayout<Int32>.stride)
        self.screenSize = screenSize
        self.renderSize = renderSize
        super.init()
        self.device = device
        
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalTexture = device?.makeTexture(descriptor: finalDesc)
        
        let s = MTLSamplerDescriptor()
//        s.magFilter = .linear
//        s.minFilter = .linear
        self.samplerState = device?.makeSamplerState(descriptor: s)
    }
    
    func render(commandBuffer: MTLCommandBuffer,
                position: UnsafeMutableRawPointer?,
                renderCenter: UnsafeMutableRawPointer?,
                missleCenter: UnsafeMutableRawPointer?,
                radius: UnsafeMutableRawPointer?,
                missleRadius: UnsafeMutableRawPointer?,
                materials: UnsafeMutableRawPointer?,
                materialCount: Int,
                hasChanges: Bool,
                cameraScale: Float,
                camera: SIMD2<Float>) -> MTLTexture? {
        
        guard let position = position,
              let renderCenter = renderCenter,
              let missleCenter = missleCenter,
              let radius = radius,
              let missleRadius = missleRadius,
              let materials = materials,
              materialCount > 0,
              let clearPipelineState = clearPipelineState,
              let computeDrawStarPipelineState = computeDrawStarPipelineState,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)
        else {
            return getClearTexture(commandBuffer: commandBuffer)
        }
        
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        var uniforms = Uniforms(cameraScale: cameraScale * defaultScale, camera: camera)
        
        var materialCount = materialCount
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = starCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let starCenterBuffer = starCenterBufferProvider.nextUniformsBuffer(data: position, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = renderCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let renderCenterBuffer = renderCenterBufferProvider.nextUniformsBuffer(data: renderCenter, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = missleCenterBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let missleCenterBuffer = missleCenterBufferProvider.nextUniformsBuffer(data: missleCenter, length: MemoryLayout<SIMD2<Float32>>.stride)
        
        _ = starRadiusBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let starRadiusBuffer = starRadiusBufferProvider.nextUniformsBuffer(data: radius, length: MemoryLayout<Float32>.stride)
        
        _ = notchRadiusBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let notchRadiusBuffer = notchRadiusBufferProvider.nextUniformsBuffer(data: missleRadius, length: MemoryLayout<Float32>.stride)
        
        _ = materialsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let materialsBuffer = materialsBufferProvider.nextUniformsBuffer(data: materials, length: MemoryLayout<StarMaterialData>.stride * materialCount)
        
        _ = materialCountsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let materialCountBuffer = materialCountsBufferProvider.nextUniformsBuffer(data: &materialCount, length: MemoryLayout<Int32>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.starCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.renderCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.missleCenterBufferProvider.avaliableResourcesSemaphore.signal()
            self.starRadiusBufferProvider.avaliableResourcesSemaphore.signal()
            self.notchRadiusBufferProvider.avaliableResourcesSemaphore.signal()
            self.materialsBufferProvider.avaliableResourcesSemaphore.signal()
            self.materialCountsBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        dispatchAuto(encoder: computeEncoder, state: clearPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(computeDrawStarPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(starCenterBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(missleCenterBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(renderCenterBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(starRadiusBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(notchRadiusBuffer, offset: 0, index: 5)
        computeEncoder.setBuffer(materialsBuffer, offset: 0, index: 6)
        computeEncoder.setBuffer(materialCountBuffer, offset: 0, index: 7)
        dispatchAuto(encoder: computeEncoder, state: clearPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
