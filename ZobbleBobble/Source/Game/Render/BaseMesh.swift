//
//  BaseMesh.swift
//  ZobbleBobble
//
//  Created by Rost on 04.01.2023.
//

import Foundation
import MetalKit

class BaseMesh {
    weak var device: MTLDevice?
    private var clearTexture: MTLTexture?
    
    lazy var clearPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fill_clear")!)
    }()
    
    func getClearTexture(commandBuffer: MTLCommandBuffer) -> MTLTexture {
        if let clearTexture = clearTexture {
            return clearTexture
        }
        let finalDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 1,
            height: 1,
            mipmapped: false)
        finalDesc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        let texture = device?.makeTexture(descriptor: finalDesc)!
        
        guard let clearPipelineState = clearPipelineState, let texture = texture else {
            fatalError()
        }
        
        let computePassDescriptor = MTLComputePassDescriptor()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else { return texture }
        
        let finalThreadgroupCount = MTLSize(width: 8, height: 8, depth: 1)
        let finalThreadgroups = MTLSize(width: texture.width / finalThreadgroupCount.width + 1, height: texture.height / finalThreadgroupCount.height + 1, depth: 1)
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.dispatchThreadgroups(finalThreadgroups, threadsPerThreadgroup: finalThreadgroupCount)
        
        computeEncoder.endEncoding()
        self.clearTexture = texture
        return texture
    }
}

extension BaseMesh {
    func dispatchAuto(encoder: MTLComputeCommandEncoder, state: MTLComputePipelineState, width: Int, height: Int) {
        guard let device = device else { fatalError("device is nil") }
        let nonUniformSizeSupport = device.supportsFamily(.apple4) ||
        device.supportsFamily(.apple5) ||
        device.supportsFamily(.apple6) ||
        device.supportsFamily(.apple7) ||
        device.supportsFamily(.apple8)
        
        if nonUniformSizeSupport {
            let threads = makeThreads(state: state, width: width, height: height)
            encoder.dispatchThreads(threads.0, threadsPerThreadgroup: threads.1)
        } else {
            let groups = makeThreadGroups(state: state, width: width, height: height)
            encoder.dispatchThreadgroups(groups.0, threadsPerThreadgroup: groups.1)
        }
    }
    
    private func makeThreadGroups(state: MTLComputePipelineState, width: Int, height: Int) -> (MTLSize, MTLSize) {
        let threadgroupsPerGrid = MTLSize(width: 8, height: 8, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: max(1, width / threadgroupsPerGrid.width),
                                            height: max(1, height / threadgroupsPerGrid.height),
                                            depth: 1)
        return (threadsPerThreadgroup, threadgroupsPerGrid)
    }
    
    private func makeThreads(state: MTLComputePipelineState, width: Int, height: Int) -> (MTLSize, MTLSize) {
        let w = state.threadExecutionWidth
        let h = state.maxTotalThreadsPerThreadgroup / w
        
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: width,
                                     height: height,
                                     depth: 1)
        
        return (threadsPerGrid, threadsPerThreadgroup)
    }
}
