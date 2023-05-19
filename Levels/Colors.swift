//
//  Colors.swift
//  ZobbleBobble
//
//  Created by Rost on 18.05.2023.
//

import Foundation

public enum Colors {
    public enum Stars {
        public static let mainColor: SIMD4<UInt8> = .init(rgb: 0xCCCCAA)
    }
    
    public enum Materials {
        public static let soil: SIMD4<UInt8> = .init(rgb: 0x79A800, a: 0)
        public static let sand: SIMD4<UInt8> = .init(rgb: 0xFFCD64, a: 1)
        public static let rock: SIMD4<UInt8> = .init(rgb: 0x907289, a: 2)
        public static let water: SIMD4<UInt8> = .init(rgb: 0x5350FD, a: 3)
        public static let oil: SIMD4<UInt8> = .init(rgb: 0xC74632, a: 4)
    }
    
    public enum Background {
        public static let defaultPack: SIMD4<UInt8> = .init(rgb: 0x00FF00)
    }
}
