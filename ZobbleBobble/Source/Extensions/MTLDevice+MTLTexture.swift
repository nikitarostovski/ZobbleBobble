//
//  MTLDevice+MTLTexture.swift
//  ZobbleBobble
//
//  Created by Rost on 08.08.2023.
//

import MetalKit

extension MTLDevice {
    func makeTexture(width: Int,
                     height: Int,
                     pixelFormat: MTLPixelFormat = .bgra8Unorm,
                     storageMode: MTLStorageMode = .shared,
                     textureType: MTLTextureType = .type2D,
                     sampleCount: Int = 1,
                     usage: MTLTextureUsage = [.shaderRead, .shaderWrite]) -> MTLTexture? {
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false)
        descriptor.storageMode = storageMode
        descriptor.usage = usage
        descriptor.textureType = textureType
        descriptor.sampleCount = sampleCount
        return makeTexture(descriptor: descriptor)
    }
}
