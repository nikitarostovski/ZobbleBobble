//
//  MTLDevice+MTLSamplerState.swift
//  ZobbleBobble
//
//  Created by Rost on 08.08.2023.
//

import MetalKit

extension MTLDevice {
    var linearSampler: MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        return makeSamplerState(descriptor: descriptor)
    }
    
    var nearestSampler: MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        return makeSamplerState(descriptor: descriptor)
    }
}
