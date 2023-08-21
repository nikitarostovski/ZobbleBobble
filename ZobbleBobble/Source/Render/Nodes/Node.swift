//
//  Node.swift
//  ZobbleBobble
//
//  Created by Rost on 01.08.2023.
//

import MetalKit

protocol Node: AnyObject {
    var linkedBody: (any Body)? { get }
    
    func render(commandBuffer: MTLCommandBuffer,
                cameraScale: Float32,
                camera: SIMD2<Float32>) -> MTLTexture?
}
