//
//  SIMD+Extensions.swift
//  ZobbleBobble
//
//  Created by Rost on 30.04.2023.
//

import Foundation

extension SIMD4 where Scalar == UInt8 {
    func mix(with value: Self, progress: CGFloat) -> Self {
        if progress >= 1 { return value }
        if progress <= 0 { return self }
        return SIMD4<UInt8>(UInt8(CGFloat(x) + (CGFloat(value.x) - CGFloat(x)) * progress),
                            UInt8(CGFloat(y) + (CGFloat(value.y) - CGFloat(y)) * progress),
                            UInt8(CGFloat(z) + (CGFloat(value.z) - CGFloat(z)) * progress),
                            UInt8(CGFloat(w) + (CGFloat(value.w) - CGFloat(w)) * progress))
    }
}
