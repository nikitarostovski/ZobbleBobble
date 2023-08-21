//
//  Colors.swift
//  Blueprints
//
//  Created by Rost on 21.08.2023.
//

import Foundation

enum Colors {
    enum Materials {
        static let solid: SIMD4<UInt8> = .init(rgb: 0xFF0000, a: 0)
        static let liquid: SIMD4<UInt8> = .init(rgb: 0x00FF00, a: 1)
        static let dusty: SIMD4<UInt8> = .init(rgb: 0x0000FF, a: 2)
    }
}
