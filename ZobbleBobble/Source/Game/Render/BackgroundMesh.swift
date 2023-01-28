//
//  BackgroundMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 03.01.2023.
//

import MetalKit

class BackgroundMesh {
    struct Uniforms {
        let cameraScale: Float
        let camera: SIMD2<Float>
    }
    
    private lazy var fillBackgroundPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fill_background")!)
    }()
    
    weak var device: MTLDevice?
    var vertexBuffers: [MTLBuffer]
    var uniformsBuffer: MTLBuffer?
    var vertexCount: Int
    var finalTexture: MTLTexture?
    
    private let screenSize: CGSize
    private let renderSize: CGSize
    
    init(_ device: MTLDevice?, screenSize: CGSize, renderSize: CGSize) {
        self.screenSize = screenSize
        self.renderSize = renderSize
        self.device = device
        self.vertexBuffers = []
        self.vertexCount = 0
        
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(renderSize.width),
            height: Int(renderSize.height),
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        self.finalTexture = device?.makeTexture(descriptor: finalDesc)
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
        guard !vertexBuffers.isEmpty else { return nil }
        guard let fillBackgroundPipelineState = fillBackgroundPipelineState else { return nil }
        guard let finalTexture = finalTexture else { return nil }
        
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return nil }
        
        let finalThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let finalThreadgroups = MTLSize(width: finalTexture.width / finalThreadgroupCount.width + 1, height: finalTexture.height / finalThreadgroupCount.height + 1, depth: 1)
        
        computeEncoder.setComputePipelineState(fillBackgroundPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
        vertexBuffers.enumerated().forEach {
            computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
        }
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
