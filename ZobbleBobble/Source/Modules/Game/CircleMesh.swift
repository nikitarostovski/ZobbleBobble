//
//  CircleMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class CircleMesh: BaseMesh {
    struct Uniforms {
        let downScale: Float
        let cameraScale: Float
        let camera: SIMD2<Float>
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
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "metaballs_circle")!)
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
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "threshold_filter_circle")!)
    }()
    
    var vertexBuffers: [MTLBuffer]
    var angleBuffer: MTLBuffer?
    var thresholdBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var blurRadiusBuffer: MTLBuffer?
    var fadeMultiplierBuffer: MTLBuffer?
    
    var vertexCount: Int
    let primitiveType: MTLPrimitiveType = .point
    var samplerState: MTLSamplerState?
    
    var textureScale: Float = 0.4
    var fadeMultiplier: Float = 0.7
    var blurRadius: Int?
    var lowResTexture: MTLTexture?
    var colorLowResTexture: MTLTexture?
    var finalTexture: MTLTexture?
    
    init(_ device: MTLDevice?, size: CGSize) {
        self.vertexBuffers = []
        self.vertexCount = 0
        super.init()
        self.device = device
        
        let width = Int(size.width * CGFloat(textureScale))
        let height = Int(size.height * CGFloat(textureScale))
        guard width > 0, height > 0 else { return }
        
        self.textureScale /= Float(UIScreen.main.bounds.width / size.width)
        
        let lowResDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        lowResDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.lowResTexture = device?.makeTexture(descriptor: lowResDesc)
        
        let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        colorDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.colorLowResTexture = device?.makeTexture(descriptor: colorDesc)
        
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalTexture = device?.makeTexture(descriptor: finalDesc)
        
        let s = MTLSamplerDescriptor()
//        s.magFilter = .linear
//        s.minFilter = .linear
        self.samplerState = device?.makeSamplerState(descriptor: s)
        
        let blurRadius: Int = Int(min(width, height) / 64)
        //        let blurRadius: Int = Int(1.0 / textureScale)
        self.blurRadius = blurRadius
        self.blurRadiusBuffer = device?.makeBuffer(bytes: &self.blurRadius, length: MemoryLayout<Int>.stride)
        
        self.fadeMultiplierBuffer = device?.makeBuffer(bytes: &fadeMultiplier, length: MemoryLayout<Float>.stride)
    }
    
    func updateMeshIfNeeded(positions: UnsafeMutableRawPointer?,
                            radii: UnsafeMutableRawPointer?,
                            colors: UnsafeMutableRawPointer?,
                            count: Int?,
                            cameraScale: Float,
                            camera: SIMD2<Float>) {
        
        guard let device = device, let positions = positions, let radii = radii, let colors = colors, var count = count else {
            self.vertexBuffers = []
            self.vertexCount = 0
            return
        }
        
        var uniforms = Uniforms(downScale: textureScale, cameraScale: cameraScale, camera: camera)
        
        let positionBuffer = device.makeBuffer(
            bytes: positions,
            length: MemoryLayout<SIMD2<Float32>>.stride * count,
            options: .storageModeShared)!
        let radiusBuffer = device.makeBuffer(
            bytes: radii,
            length: MemoryLayout<Float32>.stride * count,
            options: .storageModeShared)!
        let colorBuffer = device.makeBuffer(
            bytes: colors,
            length: MemoryLayout<SIMD4<UInt8>>.stride * count,
            options: .storageModeShared)!
        let countBuffer = device.makeBuffer(
            bytes: &count,
            length: MemoryLayout<Int>.stride,
            options: .storageModeShared)!
        
        
        self.uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: [])!
        
        self.vertexBuffers = [positionBuffer, radiusBuffer, colorBuffer, countBuffer]
        self.vertexCount = count
    }
    
    func render(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard !vertexBuffers.isEmpty else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let initPipelineState = initPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeMetaballsPipelineState = computeMetaballsPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeThresholdPipelineState = computeThresholdPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeUpscalePipelineState = computeUpscalePipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let lowResTexture = lowResTexture, let finalTexture = finalTexture, let colorLowResTexture = colorLowResTexture else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeBlurPipelineState = computeBlurPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return getClearTexture(commandBuffer: commandBuffer) }
        
        let lowResThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let lowResThreadgroups = MTLSize(width: lowResTexture.width / lowResThreadgroupCount.width + 1, height: lowResTexture.height / lowResThreadgroupCount.height + 1, depth: 1)
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
        computeEncoder.setTexture(colorLowResTexture, index: 2)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        vertexBuffers.enumerated().forEach {
            computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
        }
        computeEncoder.dispatchThreadgroups(lowResThreadgroups, threadsPerThreadgroup: lowResThreadgroupCount)
        
        computeEncoder.setComputePipelineState(computeUpscalePipelineState)
        computeEncoder.setTexture(lowResTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setSamplerState(samplerState, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.setComputePipelineState(computeBlurPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(finalTexture, index: 1)
        computeEncoder.setBuffer(blurRadiusBuffer, offset: 0, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.setComputePipelineState(computeThresholdPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setTexture(colorLowResTexture, index: 1)
        computeEncoder.setTexture(finalTexture, index: 2)
        computeEncoder.setSamplerState(samplerState, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
