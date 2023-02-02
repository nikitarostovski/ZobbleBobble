//
//  CGRect+Colors.swift
//  ZobbleBobble
//
//  Created by Rost on 31.01.2023.
//

import Foundation

extension CGRect {
    init(_ color: SIMD4<UInt8>) {
        self = CGRect(x: CGFloat(color.x), y: CGFloat(color.y), width: CGFloat(color.z), height: CGFloat(color.w))
    }
    
    var simdColor: SIMD4<UInt8> {
        SIMD4<UInt8>(UInt8(origin.x), UInt8(origin.y), UInt8(size.width), UInt8(size.height))
    }
}
