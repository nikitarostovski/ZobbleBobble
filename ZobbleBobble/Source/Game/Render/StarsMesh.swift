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
        let transitionProgress: Float32
        let missleOffset: Float32
        let camera: SIMD2<Float32>
    }
    
    private lazy var computeDrawStarPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "draw_star")!)
    }()
    
    var vertexBuffers: [[MTLBuffer]]
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
    
    func updateMeshIfNeeded(positions: [UnsafeMutableRawPointer],
                            radii: [UnsafeMutableRawPointer],
                            missleRadii: [UnsafeMutableRawPointer],
                            mainColors: [UnsafeMutableRawPointer],
                            materials: [UnsafeMutableRawPointer],
                            transitionProgress: Float,
                            materialCounts: [Int],
                            hasChanges: Bool,
                            cameraScale: Float,
                            camera: SIMD2<Float>) {
        
        guard let device = device, positions.count > 0, positions.count == radii.count, positions.count == mainColors.count, positions.count == materialCounts.count, positions.count == materials.count else {
            self.vertexBuffers = []
            self.vertexCount = 0
            return
        }
        
        let defaultScale = Float(renderSize.width / screenSize.width)
        var uniforms = Uniforms(cameraScale: cameraScale * defaultScale, transitionProgress: transitionProgress, missleOffset: Float32(Settings.starMissleCenterOffset), camera: camera)
        
        
        if hasChanges {
            self.vertexBuffers.removeAll()
            for i in positions.indices {
                var materialCount = materialCounts[i]
                guard materialCount > 0 else { continue }
                
                let positionBuffer = device.makeBuffer(
                    bytes: positions[i],
                    length: MemoryLayout<SIMD2<Float32>>.stride,
                    options: .storageModeShared)!
                let radiusBuffer = device.makeBuffer(
                    bytes: radii[i],
                    length: MemoryLayout<Float32>.stride,
                    options: .storageModeShared)!
                let missleRadiusBuffer = device.makeBuffer(
                    bytes: missleRadii[i],
                    length: MemoryLayout<Float32>.stride,
                    options: .storageModeShared)!
                let mainColorBuffer = device.makeBuffer(
                    bytes: mainColors[i],
                    length: MemoryLayout<SIMD4<UInt8>>.stride,
                    options: .storageModeShared)!
                let materialsBuffer = device.makeBuffer(
                    bytes: materials[i],
                    length: MemoryLayout<StarMaterialData>.stride * materialCounts[i],
                    options: .storageModeShared)!
                
                
                let materialsCountPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<StarMaterialData>.stride,
                                                                        alignment: MemoryLayout<Int>.alignment)
                materialsCountPointer.copyMemory(from: &materialCount, byteCount: MemoryLayout<Int>.stride)
                
                let materialCountsBuffer = device.makeBuffer(
                    bytes: &materialCount,
                    length: MemoryLayout<Int>.stride,
                    options: .storageModeShared)!
                
                let starBuffers = [positionBuffer, radiusBuffer, missleRadiusBuffer, mainColorBuffer, materialsBuffer, materialCountsBuffer]
                self.vertexBuffers.append(starBuffers)
                self.vertexCount = positions.count
            }
        }
        
        self.uniformsBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: [])!
        
    }
    
    func render(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard !vertexBuffers.isEmpty else { return getClearTexture(commandBuffer: commandBuffer) }
        
        guard let clearPipelineState = clearPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let computeDrawStarPipelineState = computeDrawStarPipelineState else { return getClearTexture(commandBuffer: commandBuffer) }
        guard let finalTexture = finalTexture else { return getClearTexture(commandBuffer: commandBuffer) }
        
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return getClearTexture(commandBuffer: commandBuffer) }
        
//        let circlesThreadgroupCount = MTLSize(width: 8, height: 1, depth: 1)
//        let circlesThreadgroups = MTLSize(width: self.vertexCount / circlesThreadgroupCount.width + 1, height: 1, depth: 1)
        
        let finalThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let finalThreadgroups = MTLSize(width: finalTexture.width / finalThreadgroupCount.width + 1, height: finalTexture.height / finalThreadgroupCount.height + 1, depth: 1)
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(finalTexture, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        for buffers in vertexBuffers {
            computeEncoder.setComputePipelineState(computeDrawStarPipelineState)
            computeEncoder.setTexture(finalTexture, index: 0)
            computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
            buffers.enumerated().forEach {
                computeEncoder.setBuffer($1, offset: 0, index: $0 + 1)
            }
            computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        }
        
        computeEncoder.endEncoding()
        
        return finalTexture
    }
}
