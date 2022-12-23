//
//  PolygonMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 22.12.2022.
//

import MetalKit

class PolygonMesh: Mesh {
    private static var defaultVertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .uchar4
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[1].stride = MemoryLayout<SIMD4<UInt8>>.stride
        return vertexDescriptor
    }
    
    var isVisible = true
    
    weak var device: MTLDevice?
    var vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    var vertexCount: Int
    let primitiveType: MTLPrimitiveType = .triangle
    
    private var currentPosition: SIMD2<Float>?
    
    init() {
        self.vertexBuffers = []
        self.vertexDescriptor = Self.defaultVertexDescriptor
        self.vertexCount = 0
    }
    
    func updateMeshIfNeeded(positions: UnsafeMutableRawPointer,
                            count: Int,
                            radius: CGFloat,
                            color: SIMD4<UInt8>,
                            sideCount: Int = 64) {
        
//        guard let device = device, sideCount != vertexCount || position != currentPosition else { return }
//
//        var positions = [SIMD2<Float>]()
//        var colors = [SIMD4<UInt8>]()
//        var angle: Float = .pi / 2
//        let deltaAngle = (2 * .pi) / Float(sideCount)
//        for _ in 0..<sideCount {
//            positions.append(SIMD2<Float>(position.x + Float(radius) * cos(angle),
//                                          position.y + Float(radius) * sin(angle)))
//            colors.append(color)
//            positions.append(SIMD2<Float>(position.x + Float(radius) * cos(angle + deltaAngle),
//                                          position.y + Float(radius) * sin(angle + deltaAngle)))
//            colors.append(color)
//            positions.append(SIMD2<Float>(0, 0))
//            colors.append(color)
//            angle += deltaAngle
//        }
//
//        let positionBuffer = device.makeBuffer(
//            bytes: positions,
//            length: MemoryLayout<SIMD2<Float>>.stride * positions.count,
//            options: .storageModeShared)!
//
//        let colorBuffer = device.makeBuffer(
//            bytes: [color],
//            length: MemoryLayout<SIMD4<UInt8>>.stride,
//            options: .storageModeShared)!
//
//        self.vertexBuffers = [positionBuffer, colorBuffer]
//        self.vertexCount = positions.count
//        self.currentPosition = position
    }
    
    func updateMeshIfNeeded(vertices: [SIMD2<Float>],
                            color: SIMD4<UInt8>) {
        
//        guard let device = device, vertices.count != vertexCount else { return }
//        
//        let positionBuffer = device.makeBuffer(
//            bytes: vertices,
//            length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
//            options: .storageModeShared)!
//        
//        let colorBuffer = device.makeBuffer(
//            bytes: [color],
//            length: MemoryLayout<SIMD4<UInt8>>.stride,
//            options: .storageModeShared)!
//        
//        self.vertexBuffers = [positionBuffer, colorBuffer]
//        self.vertexCount = vertices.count
    }
}
