//
//  BufferProvider.swift
//  ZobbleBobble
//
//  Created by Rost on 01.05.2023.
//

import Metal

final class BufferProvider {
    let inflightBuffersCount: Int
    
    private weak var device: MTLDevice?
    private var uniformsBuffers = [MTLBuffer]()
    private var avaliableBufferIndex: Int = 0
    
    var avaliableResourcesSemaphore: DispatchSemaphore
    
    init(device: MTLDevice?, inflightBuffersCount: Int, bufferSize: Int) {
        self.device = device
        self.inflightBuffersCount = inflightBuffersCount
        self.avaliableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)
        
        for _ in 0...inflightBuffersCount-1 {
            if let uniformsBuffer = device?.makeBuffer(length: bufferSize, options: .storageModeShared) {
                uniformsBuffers.append(uniformsBuffer)
            }
        }
    }
    
    func nextUniformsBuffer(data: UnsafeMutableRawPointer, length: Int) -> MTLBuffer {
        let buffer = uniformsBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()

        memcpy(bufferPointer, data, length)

        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount {
            avaliableBufferIndex = 0
        }

        return buffer
    }
    
    deinit {
        for _ in 0...self.inflightBuffersCount {
            self.avaliableResourcesSemaphore.signal()
        }
    }
}
