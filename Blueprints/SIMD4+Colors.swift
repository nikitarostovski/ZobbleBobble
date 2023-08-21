//
//  SIMD4+Colors.swift
//  Blueprints
//
//  Created by Rost on 21.08.2023.
//

import Foundation

extension SIMD4 where Scalar == UInt8 {
    init(red: UInt8, green: UInt8, blue: UInt8, a: UInt8) {
        self.init(red, green, blue, a)
    }

    init(rgb: UInt, a: UInt8 = 255) {
        self.init(
            red: UInt8((rgb >> 16) & 0xFF),
            green: UInt8((rgb >> 8) & 0xFF),
            blue: UInt8(rgb & 0xFF),
            a: a
        )
    }
}
