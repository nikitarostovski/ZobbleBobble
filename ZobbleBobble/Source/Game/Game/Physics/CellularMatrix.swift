//
//  Cells.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 11.09.2023.
//

import Foundation
import MetalKit

final class CellularMatrix {
    private let syncQueue = DispatchQueue(label: "matrix.sync")
    private let innerArraySize: Int
    private let outerArraySize: Int
    private var texture: MTLTexture?
    private var device: MTLDevice?
    
    let positionBufferProvider: BufferProvider
    let velocityBufferProvider: BufferProvider
    let colorBufferProvider: BufferProvider
    
    private lazy var clearPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "clear_cells")!)
    }()
    
    private lazy var drawPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fill_cells")!)
    }()
    
    init(width: Int, height: Int) {
        innerArraySize = width
        outerArraySize = height
        
        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
            self.texture = device.makeTexture(width: width, height: height, pixelFormat: .rgba8Unorm, storageMode: .managed)
        }
        
        self.positionBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.Physics.maxParticleCount)
        self.velocityBufferProvider = BufferProvider(device: device,
                                                     inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                     bufferSize: MemoryLayout<SIMD2<Float32>>.stride * Settings.Physics.maxParticleCount)
        self.colorBufferProvider = BufferProvider(device: device,
                                                  inflightBuffersCount: Settings.Graphics.inflightBufferCount,
                                                  bufferSize: MemoryLayout<SIMD4<UInt8>>.stride * Settings.Physics.maxParticleCount)
    }
    
    func update(count: Int,
                positions: UnsafeMutableRawPointer?,
                colors: UnsafeMutableRawPointer?,
                velocities: UnsafeMutableRawPointer?) -> MTLTexture? {
        
        guard count > 0,
              let positions = positions,
              let colors = colors,
              let velocities = velocities,
              let drawPipelineState = drawPipelineState,
              let clearPipelineState = clearPipelineState,
              let texture = texture,
              let queue = device?.makeCommandQueue(),
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder()
        else { return nil }
        
    
        _ = positionBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let positionBuffer = positionBufferProvider.nextUniformsBuffer(data: positions,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * count)
        
        _ = velocityBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let velocityBuffer = velocityBufferProvider.nextUniformsBuffer(data: velocities,
                                                                       length: MemoryLayout<SIMD2<Float32>>.stride * count)
        
        _ = colorBufferProvider.avaliableResourcesSemaphore.wait(timeout: .distantFuture)
        let colorBuffer = colorBufferProvider.nextUniformsBuffer(data: colors,
                                                                 length: MemoryLayout<SIMD4<UInt8>>.stride * count)
        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }
            positionBufferProvider.avaliableResourcesSemaphore.signal()
            velocityBufferProvider.avaliableResourcesSemaphore.signal()
            colorBufferProvider.avaliableResourcesSemaphore.signal()
        }
        
        // clear
        encoder.setComputePipelineState(clearPipelineState)
        encoder.setTexture(texture, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: encoder, state: clearPipelineState, width: texture.width, height: texture.height)
        
        // draw
        encoder.setComputePipelineState(drawPipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setBuffer(positionBuffer, offset: 0, index: 0)
        encoder.setBuffer(velocityBuffer, offset: 0, index: 1)
        encoder.setBuffer(colorBuffer, offset: 0, index: 2)
        
        let gridSize = MTLSize(width: count, height: 1, depth: 1)
        let threadgroupSize = MTLSize(width: min(count, drawPipelineState.maxTotalThreadsPerThreadgroup), height: 1, depth: 1)
        encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
        
//        ThreadHelper.dispatchAuto(device: device, encoder: encoder, state: drawPipelineState, width: count, height: 1)
        
        
        encoder.endEncoding()
        
        commandBuffer.commit()
        
        return texture
    }
}
