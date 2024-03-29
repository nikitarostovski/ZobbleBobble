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
                     storageMode: MTLStorageMode = .private,
                     textureType: MTLTextureType = .type2D,
                     sampleCount: Int = 1,
                     usage: MTLTextureUsage = [.shaderRead, .shaderWrite]) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
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
