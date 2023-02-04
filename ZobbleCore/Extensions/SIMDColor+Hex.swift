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
