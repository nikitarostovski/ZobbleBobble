//
//  LiquidMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit
import Levels

class LiquidMesh: BaseMesh {
    struct Uniforms {
        let particleRadius: Float32
        let downScale: Float32
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
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .r8Unorm
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        renderPipelineDescriptor.sampleCount = 1;
        
        return try? device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
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
    
    private lazy var computeAlphaPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "crop_alpha_texture")!)
    }()
    
    private lazy var computeSufraceFilterPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "surface_filter")!)
    }()
    
    let computePassDescriptor = MTLComputePassDescriptor()
    
    var uniqueMaterials: [MaterialType] = [] {
        didSet {
            updateInstances()
        }
    }
    
    let positionBufferProvider: BufferProvider
    let velocityBufferProvider: BufferProvider
    let colorBufferProvider: BufferProvider
    let uniformsBufferProvider: BufferProvider
    let fadeMultiplierBufferProvider: BufferProvider
    let pointCountBufferProvider: BufferProvider
    let surfaceThicknessBufferProvider: BufferProvider
    let textureCountBufferProvider: BufferProvider
    
    var pointCount = 0
    var fadeMultiplier: Float = 0
    
    var mainColorBuffer: MTLBuffer?
    
    var nearestSamplerState: MTLSamplerState?
    var linearSamplerState: MTLSamplerState?
    
    private(set) var instances = [LiquidInstance]()
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    private lazy var surfaceTexture: MTLTexture? = {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        return device?.makeTexture(descriptor: desc)
    }()
    
    init?(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
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
        self.screenSize = screenSize
        self.renderSize = renderSize
        
        
        let width = Int(renderSize.width * CGFloat(Settings.Graphics.metaballsDownscale))
        let height = Int(renderSize.height * CGFloat(Settings.Graphics.metaballsDownscale))
        guard width > 0, height > 0 else { return nil }
        
        super.init()
        self.device = device
        
        let nearestSamplerDescriptor = MTLSamplerDescriptor()
        nearestSamplerDescriptor.magFilter = .nearest
        nearestSamplerDescriptor.minFilter = .nearest
        self.nearestSamplerState = device?.makeSamplerState(descriptor: nearestSamplerDescriptor)
        
        let linearSamplerDescriptor = MTLSamplerDescriptor()
        linearSamplerDescriptor.magFilter = .linear
        linearSamplerDescriptor.minFilter = .linear
        self.linearSamplerState = device?.makeSamplerState(descriptor: linearSamplerDescriptor)
        
        updateInstances()
    }
    
    private func updateInstances() {
        let currentMaterials = self.instances.map { $0.material }
        // remove old
        self.instances = self.instances.compactMap {
            uniqueMaterials.contains($0.material) ? $0 : nil
        }
        // add new
        self.instances += uniqueMaterials.compactMap { m -> LiquidInstance? in
            guard !currentMaterials.contains(m) else { return nil }
            return LiquidInstance(device, screenSize: screenSize, renderSize: renderSize, material: m)
        }
    }
    
    func render(commandBuffer: MTLCommandBuffer,
                vertexCount: Int?,
                staticVertexCount: Int?,
                fadeMultiplier: Float,
                vertices: UnsafeMutableRawPointer?,
                staticVertices: UnsafeMutableRawPointer?,
                velocities: UnsafeMutableRawPointer?,
                staticVelocities: UnsafeMutableRawPointer?,
                colors: UnsafeMutableRawPointer?,
                staticColors: UnsafeMutableRawPointer?,
                particleRadius: Float32,
                cameraScale: Float32,
                camera: SIMD2<Float32>,
                planetActualScale: Float) -> [MTLTexture] {
        
        let vertexCount = vertexCount ?? 0
        let staticVertexCount = staticVertexCount ?? 0
        self.pointCount = vertexCount + staticVertexCount
        
        guard let vertices = vertices,
              let velocities = velocities,
              let colors = colors,
              let nearestSamplerState = nearestSamplerState,
              let linearSamplerState = linearSamplerState,
              pointCount > 0
        else {
            return []
        }
        
        self.fadeMultiplier = fadeMultiplier
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        var uniforms = Uniforms(particleRadius: particleRadius * planetActualScale,
                                downScale: Settings.Graphics.metaballsDownscale,
                                cameraScale: cameraScale * defaultScale,
                                camera: camera)
        
        _ = uniformsBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let uniformsBuffer = uniformsBufferProvider.nextUniformsBuffer(data: &uniforms, length: MemoryLayout<Uniforms>.stride)
        
        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: vertices,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount,
                                                                       data2: staticVertices,
                                                                       length2: MemoryLayout<SIMD2<Float32>>.stride * staticVertexCount)
        
        _ = velocityBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let velocityBuffer = velocityBufferProvider.nextUniformsBuffer(data: velocities,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount,
                                                                       data2: staticVelocities,
                                                                       length2: MemoryLayout<SIMD2<Float32>>.stride * staticVertexCount)
        
        _ = colorBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let colorBuffer = colorBufferProvider.nextUniformsBuffer(data: colors,
                                                                 length: MemoryLayout<SIMD4<UInt8>>.stride * vertexCount,
                                                                 data2: staticColors,
                                                                 length2: MemoryLayout<SIMD4<UInt8>>.stride * staticVertexCount)
        
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
              let computeUpscalePipelineState = computeUpscalePipelineState,
              let computeBlurPipelineState = computeBlurPipelineState,
              let computeAlphaPipelineState = computeAlphaPipelineState,
              let surfaceTexture = surfaceTexture,
              let computeSufraceFilterPipelineState = computeSufraceFilterPipelineState
        else {
            return []
        }
        
        let alphaTextures = instances.compactMap {
            $0.renderAlphaTexture(commandBuffer: commandBuffer,
                                  uniformsBuffer: uniformsBuffer,
                                  positionBuffer: positionBuffer,
                                  velocityBuffer: velocityBuffer,
                                  colorBuffer: colorBuffer,
                                  metaballsPipelineState: metaballsPipelineState,
                                  computeUpscalePipelineState: computeUpscalePipelineState,
                                  computeBlurPipelineState: computeBlurPipelineState,
                                  linearSampler: linearSamplerState,
                                  pointCount: pointCount)
        }
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)!
        for i in 0..<alphaTextures.count {
            let texturesA = alphaTextures[i]
            for j in (i + 1)..<alphaTextures.count {
                let texturesB = alphaTextures[j]

                computeEncoder.setComputePipelineState(computeAlphaPipelineState)
                computeEncoder.setTexture(texturesA.0, index: 0)
                computeEncoder.setTexture(texturesB.0, index: 1)
                computeEncoder.setTexture(texturesA.1, index: 2)
                computeEncoder.setTexture(texturesB.1, index: 3)
                computeEncoder.setSamplerState(linearSamplerState, index: 0)
                ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: computeAlphaPipelineState, width: texturesA.1.width, height: texturesA.1.height)
            }
        }
        
        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(surfaceTexture, index: 0)
        computeEncoder.setTexture(surfaceTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: initPipelineState, width: surfaceTexture.width, height: surfaceTexture.height)
        
        computeEncoder.endEncoding()
        
        let finalTextures = instances.compactMap {
            $0.renderFinalTexture(commandBuffer: commandBuffer,
                                  fadeMultiplierBuffer: fadeMultiplierBuffer,
                                  initPipelineState: initPipelineState,
                                  computeThresholdPipelineState: computeThresholdPipelineState,
                                  linearSampler: linearSamplerState,
                                  nearestSampler: nearestSamplerState)
        }
        
        let computeEncoderSurface = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor)!
        let allTextures = [surfaceTexture] + finalTextures
        var textureCount = allTextures.count
        
        _ = textureCountBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let textureCountBuffer = textureCountBufferProvider.nextUniformsBuffer(data: &textureCount,
                                                                                   length: MemoryLayout<Int>.stride)
        
        
        
        var thickness = Int(Float(Settings.Graphics.planetSurfaceThickness) * planetActualScale)
        _ = surfaceThicknessBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let surfaceThicknessBuffer = surfaceThicknessBufferProvider.nextUniformsBuffer(data: &thickness,
                                                                                   length: MemoryLayout<Int>.stride)
        
        commandBuffer.addCompletedHandler { _ in
            self.textureCountBufferProvider.avaliableResourcesSemaphore.signal()
            self.surfaceThicknessBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        computeEncoderSurface.setComputePipelineState(computeSufraceFilterPipelineState)
        computeEncoderSurface.setTextures(allTextures, range: 0..<allTextures.count)
        computeEncoderSurface.setBuffer(textureCountBuffer, offset: 0, index: 0)
        computeEncoderSurface.setBuffer(surfaceThicknessBuffer, offset: 0, index: 1)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoderSurface, state: computeSufraceFilterPipelineState, width: surfaceTexture.width, height: surfaceTexture.height)
        computeEncoderSurface.endEncoding()
        
        return allTextures
    }
}
