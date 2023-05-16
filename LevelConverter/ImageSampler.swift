//
//  ImageSampler.swift
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
//

import Foundation
import MetalKit
import Levels

final class ImageSampler {
    private let maxPointCount = 100_000_00
    
    let width: Int
    let height: Int
    
    private weak var device: MTLDevice?
    private var texture: MTLTexture
    private let commandQueue: MTLCommandQueue
    private let computePassDescriptor = MTLComputePassDescriptor()
    private let positionBufferProvider: BufferProvider
    private let resultBufferProvider: BufferProvider
    private let linearSampler: MTLSamplerState?
    
    private lazy var computeSamplePipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        guard let function = library.makeFunction(name: "get_pixel") else {
            fatalError("Unable to create function from a Metal library")
        }
        return try? device.makeComputePipelineState(function: function)
    }()
    
    
    init?(file: URL) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else { return nil }
        
        let textureLoader = MTKTextureLoader(device: device)
        guard let texture = try? textureLoader.newTexture(URL: file, options: [
//            .textureStorageMode: MTLStorageMode.shared.rawValue,
            .textureUsage: MTLTextureUsage.shaderRead.rawValue
        ])
        else { return nil }
        
        self.positionBufferProvider = BufferProvider(device: device, inflightBuffersCount: 1, bufferSize: MemoryLayout<SIMD2<Float>>.stride * maxPointCount)
        self.resultBufferProvider = BufferProvider(device: device, inflightBuffersCount: 1, bufferSize: MemoryLayout<SIMD4<Float>>.stride * maxPointCount)

        
        self.commandQueue = commandQueue
        self.device = device
        self.width = texture.width
        self.height = texture.height
        self.texture = texture
        
        let s = MTLSamplerDescriptor()
        s.magFilter = .nearest
        s.minFilter = .nearest
//        s.normalizedCoordinates = true
        self.linearSampler = device.makeSamplerState(descriptor: s)
    }
    
    /// Returns material type for passed coordinate
    /// - Parameter point: point in 0...1 range both for x and y values
    /// - Returns: type of material to spawn or nothing
    func getPixels(_ points: [CGPoint]) -> [MaterialType?] {
        guard points.count <= maxPointCount,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder(),
              let computeSamplePipelineState = computeSamplePipelineState
        else {
            return []
        }
        
        var points = points.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        
        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: &points, length: MemoryLayout<SIMD2<Float>>.stride * points.count)
        
        _ = resultBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let resultBuffer = resultBufferProvider.nextUniformsBuffer(data: &points, length: MemoryLayout<SIMD2<Float>>.stride * points.count)
        
        encoder.setComputePipelineState(computeSamplePipelineState)
        encoder.setBuffer(positionBuffer, offset: 0, index: 0)
        encoder.setBuffer(resultBuffer, offset: 0, index: 1)
        encoder.setSamplerState(linearSampler, index: 0)
        encoder.setTexture(texture, index: 0)
        
        ThreadHelper.dispatchAuto(device: device, encoder: encoder, state: computeSamplePipelineState, width: points.count, height: 1)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        positionBufferProvider.avaliableResourcesSemaphore.signal()
        resultBufferProvider.avaliableResourcesSemaphore.signal()
        
        
        
        let typedResultPointer = resultBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: maxPointCount)
        let bufferedResultPointer = UnsafeBufferPointer(start: typedResultPointer, count: points.count)
        
        
        var result = [MaterialType?]()
        for i in 0..<points.count {
            let color = bufferedResultPointer[i]
            let colorConverted = SIMD4<UInt8>(UInt8(color.x * 255.0),
                                              UInt8(color.y * 255.0),
                                              UInt8(color.z * 255.0),
                                              UInt8(color.w * 255.0))
            let material = MaterialType.parseColor(colorConverted)
//            print("\(colorConverted) \(material)")
            result.append(material)
        }
        return result
        
        
        
//        var result = [MaterialType?]()
//        for y in 0..<height {
//            for x in 0..<width {
//                let offset = (y * height + x)
////                let floatColor = resultBuffer.contents().advanced(by: offset).load(as: SIMD4<Float>.self)
//                let floatColor = resultBuffer.contents().load(as: SIMD4<Float>.self)
//
//                
//
//                let color = SIMD4<UInt8>(UInt8(floatColor.x / 255.0),
//                                         UInt8(floatColor.y / 255.0),
//                                         UInt8(floatColor.z / 255.0),
//                                         255)
//                let material = MaterialType.parseColor(color)
//                result.append(material)
//            }
//        }
//
//        return result
    }
}
