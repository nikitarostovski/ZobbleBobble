//
//  Colors.swift
//  ZobbleBobble
//
//  Created by Rost on 18.05.2023.
//

import Foundation

public enum Colors {
    public enum GUI {
        public enum Background {
            public static let dark: SIMD4<UInt8> = .init(rgb: 0x141414)
            public static let light: SIMD4<UInt8> = .init(rgb: 0x222222)
        }
        
        public enum Label {
            public static let textHeader: SIMD4<UInt8> = .init(rgb: 0xDDDDDD)
        }
        
        public enum Button {
            public static let backgroundPrimaryNormal: SIMD4<UInt8> = .init(rgb: 0x3388BB)
            public static let backgroundPrimaryHighlighted: SIMD4<UInt8> = .init(rgb: 0x4499DD)
            
            public static let backgroundSecondaryNormal: SIMD4<UInt8> = .init(rgb: 0x116699)
            public static let backgroundSecondaryHighlighted: SIMD4<UInt8> = .init(rgb: 0x2277AA)
            
            public static let backgroundUtilityNormal: SIMD4<UInt8> = .init(rgb: 0x333333)
            public static let backgroundUtilityHighlighted: SIMD4<UInt8> = .init(rgb: 0x373737)
            
            public static let titleNormal: SIMD4<UInt8> = .init(rgb: 0xBBBBBB)
            public static let titleHighlighted: SIMD4<UInt8> = .init(rgb: 0xFFFFFF)
        }
    }
    
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
