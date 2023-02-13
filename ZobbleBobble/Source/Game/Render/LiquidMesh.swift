//
//  LiquidMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit
import MetalPerformanceShaders

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
    
    var vertexBuffers: [MTLBuffer]
    var angleBuffer: MTLBuffer?
    var thresholdBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var blurRadiusBuffer: MTLBuffer?
    var fadeMultiplierBuffer: MTLBuffer?
    
    var vertexCount: Int
    var nearestSamplerState: MTLSamplerState?
    var linearSamplerState: MTLSamplerState?
    
    var fadeMultiplier: Float = 0
    var blurRadius: Int?
    var lowResTexture: MTLTexture?
    var colorTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
        self.vertexBuffers = []
        self.vertexCount = 0
        self.screenSize = screenSize
        self.renderSize = renderSize
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
        
        let blurRadius: Int = 1//Int(min(width, height) / 64)
//        let blurRadius: Int = Int(1.0 / textureScale)
        self.blurRadius = blurRadius
        self.blurRadiusBuffer = device?.makeBuffer(bytes: &self.blurRadius, length: MemoryLayout<Int>.stride)
        
        self.fadeMultiplierBuffer = device?.makeBuffer(bytes: &fadeMultiplier, length: MemoryLayout<Float>.stride)
    }
    
    func updateMeshIfNeeded(vertexCount: Int?,
                            fadeMultiplier: Float,
                            vertices: UnsafeMutableRawPointer?,
                            velocities: UnsafeMutableRawPointer?,
                            colors: UnsafeMutableRawPointer?,
                            particleRadius: Float32,
                            cameraAngle: Float32,
                            cameraScale: Float32,
                            camera: SIMD2<Float32>) {
        
        guard let device = device, var vertexCount = vertexCount, let vertices = vertices, let velocities = velocities, let colors = colors, vertexCount > 0 else {
            self.vertexBuffers = []
            self.vertexCount = 0
            return
        }
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        
        var uniforms = Uniforms(particleRadius: particleRadius,
                                downScale: Settings.liquidMetaballsDownscale,
                                cameraScale: cameraScale * defaultScale,
                                cameraAngle: cameraAngle,
                                camera: camera)
        
        self.uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: [])!
        
        let positionBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount,
            options: .storageModeShared)!
        
        let velocityBuffer = device.makeBuffer(
            bytes: velocities,
            length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount,
            options: .storageModeShared)!
        
        let colorBuffer = device.makeBuffer(
            bytes: colors,
            length: MemoryLayout<SIMD4<UInt8>>.stride * vertexCount,
            options: .storageModeShared)!
        
        let countBuffer = device.makeBuffer(
            bytes: &vertexCount,
            length: MemoryLayout<Int>.stride,
            options: .storageModeShared)!
        
        
        self.vertexBuffers = [positionBuffer, velocityBuffer, colorBuffer, countBuffer]
        self.vertexCount = vertexCount
        
        self.fadeMultiplier = fadeMultiplier
        self.fadeMultiplierBuffer = device.makeBuffer(bytes: &self.fadeMultiplier, length: MemoryLayout<Float>.stride)
    }
    
    func render(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard !vertexBuffers.isEmpty else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let initPipelineState = initPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeMetaballsPipelineState = computeMetaballsPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeThresholdPipelineState = computeThresholdPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeUpscalePipelineState = computeUpscalePipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeParticleColorsPipelineState = computeParticleColorsPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let lowResTexture = lowResTexture, let finalTexture = finalTexture, let colorTexture = colorTexture else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeBlurPipelineState = computeBlurPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return getClearTexture(commandBuffer: commandBuffer) }

        let lowResThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let lowResThreadgroups = MTLSize(width: lowResTexture.width / lowResThreadgroupCount.width + 1, height: lowResTexture.height / lowResThreadgroupCount.height + 1, depth: 1)
        
        let metaballsThreadgroupCount = MTLSize(width: 8, height: 1, depth: 1)
        let metaballsThreadgroups = MTLSize(width: self.vertexCount / metaballsThreadgroupCount.width + 1, height: 1, depth: 1)
        
        let finalThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let finalThreadgroups = MTLSize(width: finalTexture.width / finalThreadgroupCount.width + 1, height: finalTexture.height / finalThreadgroupCount.height + 1, depth: 1)
        
        computeEncoder.setComputePipelineState(initPipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(fadeMultiplierBuffer, offset: 0, index: 0)
        computeEncoder.dispatchThreadgroups(lowResThreadgroups, threadsPerThreadgroup: lowResThreadgroupCount)
        
        
        computeEncoder.setComputePipelineState(computeMetaballsPipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(lowResTexture, index: 1)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        vertexBuffers.enumerated().forEach {
            computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
        }
        computeEncoder.dispatchThreadgroups(metaballsThreadgroups, threadsPerThreadgroup: metaballsThreadgroupCount)
        
        computeEncoder.setComputePipelineState(computeParticleColorsPipelineState)
        computeEncoder.setTexture(colorTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        vertexBuffers.enumerated().forEach {
            computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
        }
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        
        computeEncoder.setComputePipelineState(computeUpscalePipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(linearSamplerState, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)

        computeEncoder.setComputePipelineState(computeBlurPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(blurRadiusBuffer, offset: 0, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)

        computeEncoder.setComputePipelineState(computeThresholdPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(colorTexture, index: 1)
        computeEncoder.setTexture(finalTexture, index: 2)
        computeEncoder.setSamplerState(nearestSamplerState, index: 0)
        computeEncoder.setSamplerState(linearSamplerState, index: 1)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
