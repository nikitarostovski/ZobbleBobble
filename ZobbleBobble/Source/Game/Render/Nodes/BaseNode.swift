//
//  BaseNode.swift
//  ZobbleBobble
//
//  Created by Rost on 04.01.2023.
//

import Foundation
import MetalKit

class BaseNode<B: Body>: Node {
    weak var device: MTLDevice?
    private var clearTexture: MTLTexture?
    
    weak var body: B?
    var linkedBody: (any Body)? { body }
    
    private lazy var clearPipelineState: MTLComputePipelineState? = {
        guard let device = device, let library = device.makeDefaultLibrary() else {
            fatalError("Unable to create default Metal library")
        }
        return try? device.makeComputePipelineState(function: library.makeFunction(name: "fill_clear")!)
    }()
    
    func getClearTexture(commandBuffer: MTLCommandBuffer) -> MTLTexture {
        if let clearTexture = clearTexture {
            return clearTexture
        }
        let texture = device?.makeTexture(width: 1, height: 1)
        
        guard let clearPipelineState = clearPipelineState, let texture = texture else {
            fatalError()
        }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return texture }
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(texture, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: clearPipelineState, width: texture.width, height: texture.height)
        
        computeEncoder.endEncoding()
        self.clearTexture = texture
        return texture
    }
    
    func render(commandBuffer: MTLCommandBuffer, cameraScale: Float32, camera: SIMD2<Float32>) -> MTLTexture? { nil }
}

extension BaseNode {
    func clearTexture(texture: MTLTexture, computeEncoder: MTLComputeCommandEncoder) {
        guard let clearPipelineState = clearPipelineState else { return }
        
        computeEncoder.setComputePipelineState(clearPipelineState)
        computeEncoder.setTexture(texture, index: 0)
        ThreadHelper.dispatchAuto(device: device, encoder: computeEncoder, state: clearPipelineState, width: texture.width, height: texture.height)
    }
}
