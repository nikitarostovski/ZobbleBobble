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
