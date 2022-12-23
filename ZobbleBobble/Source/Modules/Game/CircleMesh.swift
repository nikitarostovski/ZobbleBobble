//
//  CircleMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class CircleMesh: Mesh {
    private static var defaultVertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1
        vertexDescriptor.attributes[2].format = .uchar4
        vertexDescriptor.attributes[2].offset = 0
        vertexDescriptor.attributes[2].bufferIndex = 2
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[1].stride = MemoryLayout<Float>.stride
        vertexDescriptor.layouts[2].stride = MemoryLayout<SIMD4<UInt8>>.stride
        return vertexDescriptor
    }
    
    var isVisible = true
    
    weak var device: MTLDevice?
    var vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    var vertexCount: Int
    let primitiveType: MTLPrimitiveType = .point
    
    init() {
        self.vertexBuffers = []
        self.vertexDescriptor = Self.defaultVertexDescriptor
        self.vertexCount = 0
    }
    
    func updateMeshIfNeeded(positions: UnsafeMutableRawPointer,
                            radii: UnsafeMutableRawPointer,
                            colors: UnsafeMutableRawPointer,
                            count: Int) {
        
        guard let device = device, count != vertexCount else { return }
        
        let positionBuffer = device.makeBuffer(
            bytes: positions,
            length: MemoryLayout<SIMD2<Float>>.stride * count,
            options: .storageModeShared)!
        let radiusBuffer = device.makeBuffer(
            bytes: radii,
            length: MemoryLayout<SIMD2<Float>>.stride * count,
            options: .storageModeShared)!
        let colorBuffer = device.makeBuffer(
            bytes: colors,
            length: MemoryLayout<SIMD4<UInt8>>.stride * count,
            options: .storageModeShared)!
        
        self.vertexBuffers = [positionBuffer, radiusBuffer, colorBuffer]
        self.vertexCount = count
    }
}
