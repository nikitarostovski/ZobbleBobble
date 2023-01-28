//
//  CircleMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class CircleMesh: BaseMesh {
    struct Uniforms {
        let cameraScale: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var computeDrawCirclesPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_circles")!)
    }()
    
    var vertexBuffers: [MTLBuffer]
    var uniformsBuffer: MTLBuffer?
    
    var vertexCount: Int
    var samplerState: MTLSamplerState?
    
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
        self.screenSize = screenSize
        self.renderSize = renderSize
        self.vertexBuffers = []
        self.vertexCount = 0
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
    
    func updateMeshIfNeeded(positions: UnsafeMutableRawPointer?,
                            radii: UnsafeMutableRawPointer?,
                            colors: UnsafeMutableRawPointer?,
                            count: Int?,
                            cameraScale: Float,
                            camera: SIMD2<Float>) {
        
        guard let device = device, let positions = positions, let radii = radii, let colors = colors, var count = count, count > 0 else {
            self.vertexBuffers = []
            self.vertexCount = 0
            return
        }
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        var uniforms = Uniforms(cameraScale: cameraScale * defaultScale, camera: camera)
        
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
        
        guard let clearPipelineState = clearPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeDrawCirclesPipelineState = computeDrawCirclesPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let finalTexture = finalTexture else { return getClearTexture(commandBuffer: commandBuffer) }
        
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return getClearTexture(commandBuffer: commandBuffer) }
        
        let circlesThreadgroupCount = MTLSize(width: 8, height: 1, depth: 1)
        let circlesThreadgroups = MTLSize(width: self.vertexCount / circlesThreadgroupCount.width + 1, height: 1, depth: 1)
        
        let finalThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let finalThreadgroups = MTLSize(width: finalTexture.width / finalThreadgroupCount.width + 1, height: finalTexture.height / finalThreadgroupCount.height + 1, depth: 1)
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.setComputePipelineState(computeDrawCirclesPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        vertexBuffers.enumerated().forEach {
            computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
        }
        computeEncoder.dispatchThreadgroups(circlesThreadgroups, threadsPerThreadgroup: circlesThreadgroupCount)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
