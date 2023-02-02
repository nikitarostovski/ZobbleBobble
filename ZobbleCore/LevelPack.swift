//
//  LevelPack.swift
//  ZobbleCore
//
//  Created by Rost on 18.01.2023.
//

import UIKit

public struct LevelPackStyle {
    public let mainColor: SIMD4<UInt8>
    public let backgroundColor: SIMD4<UInt8>
}

public class LevelPack {
    public var levels: [Level]
    
    public let number: Int
    public let radius: CGFloat
    public let style: LevelPackStyle
    
    public var allMaterials: [Material] {
        levels.flatMap { $0.materials }
    }
    
    init(number: Int, levels: [Level]) {
        self.number = number
        self.levels = levels
        self.radius = 230
        self.style = Self.makeStyle(for: number)
    }
}

extension LevelPack {
    private static func makeStyle(for number: Int) -> LevelPackStyle {
        let accentHue = CGFloat(number) / 10
        let accentColor = UIColor(hue: accentHue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let backColor = UIColor(hue: accentHue + 0.5, saturation: 0.8, brightness: 0.5, alpha: 1.0)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        accentColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let mainColor = SIMD4<UInt8>(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
        
        backColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let backgroundColor = SIMD4<UInt8>(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
        
        return LevelPackStyle(mainColor: mainColor, backgroundColor: backgroundColor)
    }
}
