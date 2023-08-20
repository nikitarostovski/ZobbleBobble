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
    
    weak var body: B?
    var linkedBody: (any Body)? { body }
    
    func render(commandBuffer: MTLCommandBuffer, cameraScale: Float32, camera: SIMD2<Float32>) -> MTLTexture? { nil }
}
