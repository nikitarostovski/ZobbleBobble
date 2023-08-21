//
//  LiquidNode.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import MetalKit
import MetalPerformanceShaders

class LiquidNode: BaseNode<LiquidBody> {
    struct Uniforms {
        let particleRadius: Float32
        let downScale: Float32
        let alphaTextureRadiusModifier: Float
        let movementTextureRadiusModifier: Float
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var initPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fade_out")!)
    }()
    
    private lazy var metaballsPipelineState: MTLRenderPipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "metaballs_vertex")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "metaballs_fragment")!
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        
        return try? device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
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
    
    let metaballsRenderPassDescriptor = MTLRenderPassDescriptor()
    
    let positionBufferProvider: BufferProvider
    let velocityBufferProvider: BufferProvider
    let colorBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    let fadeMultiplierBufferProvider: BufferProvider
    let pointCountBufferProvider: BufferProvider
    let surfaceThicknessBufferProvider: BufferProvider
    let textureCountBufferProvider: BufferProvider
    
    var mainColorBuffer: MTLBuffer?
    var auxColorBuffer: MTLBuffer?
    var lowResSizeBuffer: MTLBuffer?
    var thresholdBuffer: MTLBuffer?
    var moveThresholdBuffer: MTLBuffer?
    
    var nearestSamplerState: MTLSamplerState?
    var linearSamplerState: MTLSamplerState?
    
    var lowResAlphaTexture: MTLTexture?
    var finalAlphaCorrectedTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    let renderSize: CGSize
    
    var pointCount = 0
    var fadeMultiplier: Float = 0
    
    var material: MaterialType
    var threshold: Float
    var moveThreshold: Float
    var blurSigma: Float
    
    init?(_ device: MTLDevice?, renderSize: CGSize, material: MaterialType, body: LiquidBody?) {
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
        self.fadeMultiplierBufferProvider = BufferProvider(device: device,
                                                           inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                           bufferSize: MemoryLayout<Float32>.stride)
        self.pointCountBufferProvider = BufferProvider(device: device,
                                                       inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                       bufferSize: MemoryLayout<Int>.stride)
        self.surfaceThicknessBufferProvider = BufferProvider(device: device,
                                                             inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                             bufferSize: MemoryLayout<Int>.stride)
        self.textureCountBufferProvider = BufferProvider(device: device,
                                                             inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                             bufferSize: MemoryLayout<Int>.stride)
        
        self.renderSize = renderSize
        self.material = material
        
        let width = Int(renderSize.width * CGFloat(Settings.Graphics.metaballsDownscale))
        let height = Int(renderSize.height * CGFloat(Settings.Graphics.metaballsDownscale))
        guard width > 0, height > 0, let device = device else { return nil }
        
        var size: SIMD2<Float> = SIMD2<Float>(Float(width), Float(height))
        self.lowResSizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<SIMD2<Float>>.stride)
        
        self.blurSigma = Float(Settings.Graphics.metaballsBlurSigma) * Float(material.blurModifier)
        
        self.threshold = material.cropThreshold
        self.thresholdBuffer = device.makeBuffer(bytes: &self.threshold, length: MemoryLayout<Float>.stride)
        
        self.moveThreshold = material.movementTextureThresold
        self.moveThresholdBuffer = device.makeBuffer(bytes: &self.moveThreshold, length: MemoryLayout<Float>.stride)
        
        var mainColor = material.color
        self.mainColorBuffer = device.makeBuffer(bytes: &mainColor, length: MemoryLayout<SIMD4<UInt8>>.stride)
        
        var auxColor = material.auxColor
        self.auxColorBuffer = device.makeBuffer(bytes: &auxColor, length: MemoryLayout<SIMD4<UInt8>>.stride)
        
        super.init()
        
        self.body = body
        self.device = device
        
        self.nearestSamplerState = device.nearestSampler
        self.linearSamplerState = device.linearSampler

        self.lowResAlphaTexture = device.makeTexture(width: width, height: height, usage: [.shaderRead, .shaderWrite, .renderTarget])
        self.finalTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        self.finalAlphaCorrectedTexture = device.makeTexture(width: Int(renderSize.width), height: Int(renderSize.height))
        
        metaballsRenderPassDescriptor.colorAttachments[0].loadAction = .load
        metaballsRenderPassDescriptor.colorAttachments[0].storeAction = .store
        metaballsRenderPassDescriptor.colorAttachments[0].texture = lowResAlphaTexture
        metaballsRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    override func render(commandBuffer: MTLCommandBuffer,
                         cameraScale: Float32,
                         camera: SIMD2<Float32>) -> MTLTexture? {
        
        guard let renderData = body?.renderData else { return nil }
        
        let vertices = renderData.liquidPositions
        let velocities = renderData.liquidVelocities
        let colors = renderData.liquidColors
        
        self.pointCount = renderData.liquidCount
        
        guard let nearestSamplerState = nearestSamplerState,
              let linearSamplerState = linearSamplerState,
              pointCount > 0
        else {
            return nil
        }
        
        self.fadeMultiplier = renderData.liquidFadeModifier
        
        var uniforms = Uniforms(particleRadius: renderData.particleRadius,
                                downScale: Settings.Graphics.metaballsDownscale,
                                alphaTextureRadiusModifier: material.alphaTextureRadiusModifier,
                                movementTextureRadiusModifier: material.movmentTextureRadiusModifier,
                                cameraScale: cameraScale / renderData.scale,
                                camera: camera)
        
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
        
        _ = fadeMultiplierBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let fadeMultiplierBuffer = fadeMultiplierBufferProvider.nextUniformsBuffer(data: &self.fadeMultiplier,
                                                                                   length: MemoryLayout<Float32>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.positionBufferProvider.avaliableResourcesSemaphore.signal()
            self.velocityBufferProvider.avaliableResourcesSemaphore.signal()
            self.colorBufferProvider.avaliableResourcesSemaphore.signal()
            self.uniformsBufferProvider.avaliableResourcesSemaphore.signal()
            self.fadeMultiplierBufferProvider.avaliableResourcesSemaphore.signal()
            self.pointCountBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        guard let initPipelineState = initPipelineState,
              let metaballsPipelineState = metaballsPipelineState,
              let computeThresholdPipelineState = computeThresholdPipelineState,
              let computeUpscalePipelineState = computeUpscalePipelineState
        else {
            return nil
        }
        
        let _ = renderAlphaTexture(commandBuffer: commandBuffer,
                                   uniformsBuffer: uniformsBuffer,
                                   positionBuffer: positionBuffer,
                                   velocityBuffer: velocityBuffer,
                                   colorBuffer: colorBuffer,
                                   metaballsPipelineState: metaballsPipelineState,
                                   computeUpscalePipelineState: computeUpscalePipelineState,
                                   linearSampler: linearSamplerState,
                                   pointCount: pointCount)
        
        let finalTexture = renderFinalTexture(commandBuffer: commandBuffer,
                                              fadeMultiplierBuffer: fadeMultiplierBuffer,
                                              initPipelineState: initPipelineState,
                                              computeThresholdPipelineState: computeThresholdPipelineState,
                                              linearSampler: linearSamplerState,
                                              nearestSampler: nearestSamplerState)
        return finalTexture
    }
    
    private func renderAlphaTexture(commandBuffer: MTLCommandBuffer,
                                    uniformsBuffer: MTLBuffer,
                                    positionBuffer: MTLBuffer,
                                    velocityBuffer: MTLBuffer,
                                    colorBuffer: MTLBuffer,
                                    metaballsPipelineState: MTLRenderPipelineState,
                                    computeUpscalePipelineState: MTLComputePipelineState,
                                    linearSampler: MTLSamplerState,
                                    pointCount: Int) -> MTLTexture? {
        guard var lowResAlphaTexture = lowResAlphaTexture,
              let finalAlphaCorrectedTexture = finalAlphaCorrectedTexture
        else {
            return nil
        }
        
        let metaballsEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: metaballsRenderPassDescriptor)!
        metaballsEncoder.setRenderPipelineState(metaballsPipelineState)
        metaballsEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
        metaballsEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 1)
        metaballsEncoder.setVertexBuffer(velocityBuffer, offset: 0, index: 2)
        metaballsEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 3)
        metaballsEncoder.setVertexBuffer(lowResSizeBuffer, offset: 0, index: 4)
        metaballsEncoder.setVertexBuffer(mainColorBuffer, offset: 0, index: 5)
        metaballsEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        metaballsEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: pointCount)
        metaballsEncoder.endEncoding()
        
        if let device = device, blurSigma > 0 {
            let gauss = MPSImageGaussianBlur(device: device, sigma: blurSigma)
            gauss.encode(commandBuffer: commandBuffer, inPlaceTexture: &lowResAlphaTexture, fallbackCopyAllocator: nil)
        }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        
        computeEncoder.setComputePipelineState(computeUpscalePipelineState)
        computeEncoder.setTexture(lowResAlphaTexture, index: 0)
        computeEncoder.setTexture(finalAlphaCorrectedTexture, index: 1)
        computeEncoder.setSamplerState(linearSampler, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeUpscalePipelineState, width: finalAlphaCorrectedTexture.width, height: finalAlphaCorrectedTexture.height)
        
        computeEncoder.endEncoding()
        return finalAlphaCorrectedTexture
    }
    
    private func renderFinalTexture(commandBuffer: MTLCommandBuffer,
                                    fadeMultiplierBuffer: MTLBuffer,
                                    initPipelineState: MTLComputePipelineState,
                                    computeThresholdPipelineState: MTLComputePipelineState,
                                    linearSampler: MTLSamplerState,
                                    nearestSampler: MTLSamplerState) -> MTLTexture? {
        
        guard let finalAlphaCorrectedTexture = finalAlphaCorrectedTexture,
              let lowResAlphaTexture = lowResAlphaTexture,
              let finalTexture = finalTexture,
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return finalTexture
        }
        
        computeEncoder.setComputePipelineState(computeThresholdPipelineState)
        computeEncoder.setTexture(finalAlphaCorrectedTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(mainColorBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(auxColorBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(thresholdBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(moveThresholdBuffer, offset: 0, index: 3)
        computeEncoder.setSamplerState(nearestSampler, index: 0)
        computeEncoder.setSamplerState(linearSampler, index: 1)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeThresholdPipelineState, width: finalTexture.width, height: finalTexture.height)
        
        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(lowResAlphaTexture, index: 0)
        computeEncoder.setTexture(lowResAlphaTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: initPipelineState, width: lowResAlphaTexture.width, height: lowResAlphaTexture.height)
        
        computeEncoder.endEncoding()
        return finalTexture
    }
}
