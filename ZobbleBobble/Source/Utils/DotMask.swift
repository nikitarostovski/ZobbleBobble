//
//  DotMask.swift
//  ZobbleBobble
//
//  Created by Rost on 14.08.2023.
//

import MetalKit

class DotMask {
    enum MaskType {
        case bisected
        case trisected
        case bisectedShifted
        case trisectedShifted
    }
    
    static func makeDotMask(_ type: MaskType, brightness: Float) -> CGImage? {
        let max  = UInt8(85 + brightness * 170)
        let base = UInt8((1 - brightness) * 85)
        let none = UInt8(30 + (1 - brightness) * 55)
        
        let R = UInt32(r: max, g: base, b: base)
        let G = UInt32(r: base, g: max, b: base)
        let B = UInt32(r: base, g: base, b: max)
        let M = UInt32(r: max, g: base, b: max)
        let W = UInt32(r: max, g: max, b: max)
        let N = UInt32(r: none, g: none, b: none)
        
        let maskData: [UInt32]
        let maskSize: CGSize
        switch type {
        case .bisected:
            maskData = [ M, G, N ]
            maskSize = CGSize(width: 3, height: 1)
        case .trisected:
            maskData = [ R, G, B, N ]
            maskSize = CGSize(width: 4, height: 1)
        case .bisectedShifted:
            maskData = [ M, G, N,
                         M, G, N,
                         N, N, N,
                         N, M, G,
                         N, M, G,
                         N, N, N,
                         G, N, M,
                         G, N, M,
                         N, N, N]
            maskSize = CGSize(width: 3, height: 9)
        case .trisectedShifted:
            maskData = [ R, G, B, N,
                         R, G, B, N,
                         R, G, B, N,
                         N, N, N, N,
                         B, N, R, G,
                         B, N, R, G,
                         B, N, R, G,
                         N, N, N, N]
            maskSize = CGSize(width: 4, height: 8)
        }
        
        // Create image representation in memory
        let cap = Int(maskSize.width) * Int(maskSize.height)
        let mask = calloc(cap, MemoryLayout<UInt32>.size)!
        let ptr = mask.bindMemory(to: UInt32.self, capacity: cap)
        for i in 0 ... cap - 1 {
            ptr[i] = maskData[i]
        }
        
        // Create image
        return CGImage.make(data: mask, size: maskSize)
    }
}
