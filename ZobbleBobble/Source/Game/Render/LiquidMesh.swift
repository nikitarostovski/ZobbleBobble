//
//  LiquidMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class LiquidMesh: BaseMesh {
    struct Uniforms {
        let particleRadius: Float32
        let downScale: Float32
        let cameraScale: Float32
        let cameraAngle: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var initPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fade_out")!)
    }()
    
    private lazy var computeMetaballsPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "metaballs")!)
    }()
    
    private lazy var computeParticleColorsPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fill_particle_colors")!)
    }()
    
    private lazy var computeBlurPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "blur")!)
    }()
    
    private lazy var computeUpscalePipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "upscale_texture")!)
    }()
    
    private lazy var computeThresholdPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "threshold_filter")!)
    }()
    
    let computePassDescriptor = MTLComputePassDescriptor()
    
    let positionBufferProvider: BufferProvider
    let velocityBufferProvider: BufferProvider
    let colorBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    let countBufferProvider: BufferProvider
    let fadeMultiplierBufferProvider: BufferProvider
    
    var blurRadius: Int?
    var fadeMultiplier: Float = 0
    
    let blurRadiusBuffer: MTLBuffer?
    
    var nearestSamplerState: MTLSamplerState?
    var linearSamplerState: MTLSamplerState?
    
    var lowResTexture: MTLTexture?
    var colorTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
        self.positionBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.maxParticleCount)
        self.velocityBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.maxParticleCount)
        self.colorBufferProvider = BufferProvider(device: device,
                                                  inflightBuffersCount: Settings.inflightBufferCount,
                                                  bufferSize: MemoryLayout<SIMD4<UInt8>>.stride * Settings.maxParticleCount)
        self.uniformsBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.inflightBufferCount,
                                                     bufferSize: MemoryLayout<Uniforms>.stride)
        self.countBufferProvider = BufferProvider(device: device,
                                                  inflightBuffersCount: Settings.inflightBufferCount,
                                                  bufferSize: MemoryLayout<Int32>.stride)
        self.fadeMultiplierBufferProvider = BufferProvider(device: device,
                                                           inflightBuffersCount: Settings.inflightBufferCount,
                                                           bufferSize: MemoryLayout<Float32>.stride)
        self.screenSize = screenSize
        self.renderSize = renderSize
        
        
        let blurRadius: Int = 1//Int(min(width, height) / 64)
//        let blurRadius: Int = Int(1.0 / textureScale)
        self.blurRadius = blurRadius
        self.blurRadiusBuffer = device?.makeBuffer(bytes: &self.blurRadius, length: MemoryLayout<Int>.stride)
        
        super.init()
        self.device = device
        
        let width = Int(renderSize.width * CGFloat(Settings.liquidMetaballsDownscale))
        let height = Int(renderSize.height * CGFloat(Settings.liquidMetaballsDownscale))
        guard width > 0, height > 0 else { return }
        
        let lowResDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        lowResDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.lowResTexture = device?.makeTexture(descriptor: lowResDesc)
        
        let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        colorDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.colorTexture = device?.makeTexture(descriptor: colorDesc)
        
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalTexture = device?.makeTexture(descriptor: finalDesc)
        
        let nearestSamplerDescriptor = MTLSamplerDescriptor()
        nearestSamplerDescriptor.magFilter = .nearest
        nearestSamplerDescriptor.minFilter = .nearest
        self.nearestSamplerState = device?.makeSamplerState(descriptor: nearestSamplerDescriptor)
        
        let linearSamplerDescriptor = MTLSamplerDescriptor()
        linearSamplerDescriptor.magFilter = .linear
        linearSamplerDescriptor.minFilter = .linear
        self.linearSamplerState = device?.makeSamplerState(descriptor: linearSamplerDescriptor)
    }
    
    func render(commandBuffer: MTLCommandBuffer,
                vertexCount: Int?,
                fadeMultiplier: Float,
                vertices: UnsafeMutableRawPointer?,
                velocities: UnsafeMutableRawPointer?,
                colors: UnsafeMutableRawPointer?,
                particleRadius: Float32,
                cameraAngle: Float32,
                cameraScale: Float32,
                camera: SIMD2<Float32>) -> MTLTexture? {
        
        guard var vertexCount = vertexCount,
              let vertices = vertices,
              let velocities = velocities,
              let colors = colors,
              vertexCount > 0
        else {
            return getClearTexture(commandBuffer: commandBuffer)
        }
        
        self.fadeMultiplier = fadeMultiplier
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        
        var uniforms = Uniforms(particleRadius: particleRadius,
                                downScale: Settings.liquidMetaballsDownscale,
                                cameraScale: cameraScale * defaultScale,
                                cameraAngle: cameraAngle,
                                camera: camera)
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: vertices,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount)
        
        _ = velocityBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let velocityBuffer = velocityBufferProvider.nextUniformsBuffer(data: velocities,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount)
        
        _ = colorBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let colorBuffer = colorBufferProvider.nextUniformsBuffer(data: colors,
                                                                 length: MemoryLayout<SIMD4<UInt8>>.stride * vertexCount)
        
        _ = countBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let countBuffer = countBufferProvider.nextUniformsBuffer(data: &vertexCount,
                                                                 length: MemoryLayout<Int32>.stride)
        
        _ = fadeMultiplierBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let fadeMultiplierBuffer = fadeMultiplierBufferProvider.nextUniformsBuffer(data: &self.fadeMultiplier,
                                                                                   length: MemoryLayout<Float32>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.positionBufferProvider.avaliableResourcesSemaphore.signal()
            self.velocityBufferProvider.avaliableResourcesSemaphore.signal()
            self.colorBufferProvider.avaliableResourcesSemaphore.signal()
            self.countBufferProvider.avaliableResourcesSemaphore.signal()
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.fadeMultiplierBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let initPipelineState = initPipelineState,
              let computeMetaballsPipelineState = computeMetaballsPipelineState,
              let computeThresholdPipelineState = computeThresholdPipelineState,
              let computeUpscalePipelineState = computeUpscalePipelineState,
              let computeParticleColorsPipelineState = computeParticleColorsPipelineState,
              let lowResTexture = lowResTexture,
              let finalTexture = finalTexture,
              let colorTexture = colorTexture,
              let computeBlurPipelineState = computeBlurPipelineState,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)
        else {
            return getClearTexture(commandBuffer: commandBuffer)
        }

        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        dispatchAuto(encoder: computeEncoder, state: initPipelineState, width: lowResTexture.width, height: lowResTexture.height)
        
        computeEncoder.setComputePipelineState(computeMetaballsPipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(positionBuffer, offset: 0, index: 1)
        
        dispatchAuto(encoder: computeEncoder, state: computeMetaballsPipelineState, width: vertexCount, height: 1)
        
        computeEncoder.setComputePipelineState(computeParticleColorsPipelineState)
        computeEncoder.setTexture(colorTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(positionBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(velocityBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(colorBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(countBuffer, offset: 0, index: 4)
        dispatchAuto(encoder: computeEncoder, state: computeUpscalePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(computeUpscalePipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(linearSamplerState, index: 0)
        dispatchAuto(encoder: computeEncoder, state: computeUpscalePipelineState, width: finalTexture.width, height: finalTexture.height)

        computeEncoder.setComputePipelineState(computeBlurPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(blurRadiusBuffer, offset: 0, index: 0)
        dispatchAuto(encoder: computeEncoder, state: computeUpscalePipelineState, width: finalTexture.width, height: finalTexture.height)

        computeEncoder.setComputePipelineState(computeThresholdPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(colorTexture, index: 1)
        computeEncoder.setTexture(finalTexture, index: 2)
        computeEncoder.setSamplerState(nearestSamplerState, index: 0)
        computeEncoder.setSamplerState(linearSamplerState, index: 1)
        dispatchAuto(encoder: computeEncoder, state: computeUpscalePipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
