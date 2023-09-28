//
//  ThreadHelper.swift
//  ZobbleBobble
//
//  Created by Rost on 14.05.2023.
//

import Foundation
import MetalKit
import Metal

final class ThreadHelper {
    static func dispatchAuto(device: MTLDevice?, encoder: MTLComputeCommandEncoder, state: MTLComputePipelineState, width: Int, height: Int) {
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
    
    private static func makeThreadGroups(state: MTLComputePipelineState, width: Int, height: Int) -> (MTLSize, MTLSize) {
        let w = state.threadExecutionWidth
        let h = state.maxTotalThreadsPerThreadgroup / w
        
        let threadgroupsPerGrid = MTLSize(width: w, height: h, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: max(1, width / threadgroupsPerGrid.width),
                                            height: max(1, height / threadgroupsPerGrid.height),
                                            depth: 1)
        return (threadsPerThreadgroup, threadgroupsPerGrid)
    }
    
    private static func makeThreads(state: MTLComputePipelineState, width: Int, height: Int) -> (MTLSize, MTLSize) {
        let w = state.threadExecutionWidth
        let h = state.maxTotalThreadsPerThreadgroup / w
        
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: width,
                                     height: height,
                                     depth: 1)
        
        return (threadsPerGrid, threadsPerThreadgroup)
    }
}
