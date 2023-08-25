//
//  ImageSampler.swift
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
//

import Foundation
import MetalKit

final class ImageSampler {
    private let maxPointCount = 100_000_00
    
    let width: Int
    let height: Int
    
    private weak var device: MTLDevice?
    private var texture: MTLTexture
    private let commandQueue: MTLCommandQueue
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
        guard var texture = try? textureLoader.newTexture(URL: file, options: [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue
        ]) else { return nil }
        texture = texture.makeTextureView(pixelFormat: .bgra8Unorm) ?? texture
        
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
        self.linearSampler = device.makeSamplerState(descriptor: s)
    }
    
    /// Returns points grouped by unique colors found among passed points
    /// - Parameter points: array of points in 0...1 range both for x and y values
    /// - Returns: dictionary with unique colors (found sampling with `points`) as keys and points as values
    func getPointsByUniqueColors(_ points: [CGPoint]) -> [SIMD4<UInt8>: [CGPoint]] {
        guard points.count <= maxPointCount,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder(),
              let computeSamplePipelineState = computeSamplePipelineState
        else {
            return [:]
        }
        
        var simdPoints = points.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        
        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: &simdPoints, length: MemoryLayout<SIMD2<Float>>.stride * points.count)
        
        _ = resultBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let resultBuffer = resultBufferProvider.nextUniformsBuffer(data: &simdPoints, length: MemoryLayout<SIMD2<Float>>.stride * points.count)
        
        encoder.setComputePipelineState(computeSamplePipelineState)
        encoder.setBuffer(positionBuffer, offset: 0, index: 0)
        encoder.setBuffer(resultBuffer, offset: 0, index: 1)
        encoder.setSamplerState(linearSampler, index: 0)
        encoder.setTexture(texture, index: 0)
        
        ThreadHelper.dispatchAuto(device: device, encoder: encoder, state: computeSamplePipelineState, width: simdPoints.count, height: 1)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        positionBufferProvider.avaliableResourcesSemaphore.signal()
        resultBufferProvider.avaliableResourcesSemaphore.signal()
        
        let typedResultPointer = resultBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: maxPointCount)
        let bufferedResultPointer = UnsafeBufferPointer(start: typedResultPointer, count: simdPoints.count)
        
        var pointsByColors = [SIMD4<UInt8>: [CGPoint]]()
        for i in points.indices {
            let color = SIMD4<UInt8>(UInt8(bufferedResultPointer[i].x * 255.0),
                                     UInt8(bufferedResultPointer[i].y * 255.0),
                                     UInt8(bufferedResultPointer[i].z * 255.0),
                                     UInt8(bufferedResultPointer[i].w * 255.0))
            
            var currentPoints = pointsByColors[color] ?? []
            currentPoints.append(points[i])
            pointsByColors[color] = currentPoints
        }
        return pointsByColors
    }
}
