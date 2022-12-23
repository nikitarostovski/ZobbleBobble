//
//  LiquidMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class LiquidMesh: Mesh {
    private static var defaultVertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .half2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .uchar4
        vertexDescriptor.attributes[2].offset = 0
        vertexDescriptor.attributes[2].bufferIndex = 1
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float32>>.stride
        vertexDescriptor.layouts[1].stride = MemoryLayout<Float>.stride
        vertexDescriptor.layouts[2].stride = MemoryLayout<SIMD4<UInt8>>.stride
        return vertexDescriptor
    }
    
    weak var device: MTLDevice?
    var vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    var vertexCount: Int
    let primitiveType: MTLPrimitiveType = .point
    
    var isVisible = false
    
    init() {
        self.vertexBuffers = []
        self.vertexDescriptor = Self.defaultVertexDescriptor
        self.vertexCount = 0
    }
    
    init(vertexBuffers: [MTLBuffer], vertexDescriptor: MTLVertexDescriptor, vertexCount: Int) {
        self.vertexBuffers = vertexBuffers
        self.vertexDescriptor = vertexDescriptor
        self.vertexCount = vertexCount
    }
    
    func updateMeshIfNeeded(vertexCount: Int,
                            vertices: UnsafeMutableRawPointer,
                            colors: UnsafeMutableRawPointer) {
        
        guard let device = device, vertexCount > 0 else { return }
        
        let positionBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD2<Float32>>.stride * vertexCount,
            options: .storageModeShared)!
        
        let colorBuffer = device.makeBuffer(
            bytes: colors,
            length: MemoryLayout<SIMD4<UInt8>>.stride * vertexCount,
            options: .storageModeShared)!
        
        self.vertexBuffers = [positionBuffer, colorBuffer]
        self.vertexCount = vertexCount
    }
}
