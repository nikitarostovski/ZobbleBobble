//
//  SIMDColor+Hex.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

extension String {
    public func colorFromHex(alpha: CGFloat = 1.0) -> SIMD4<UInt8> {
        var cString:String = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return SIMD4<UInt8>(0, 0, 0, 0)
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        let red = UInt8((rgbValue & 0xFF0000) >> 16)
        let green = UInt8((rgbValue & 0x00FF00) >> 8)
        let blue = UInt8((rgbValue & 0x0000FF))
        return SIMD4<UInt8>(red, green, blue, 255)
    }
}

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
