//
//  LevelPack.swift
//  ZobbleCore
//
//  Created by Rost on 18.01.2023.
//

import UIKit

public class LevelPack {
    public struct Outline {
        public var radius: CGFloat
        public var color: SIMD4<UInt8>
    }
    
    public var levels: [Level]
    
    public let number: Int
    
    public var targetOutline: Outline
    
    init(number: Int, levels: [Level]) {
        self.number = number
        self.levels = levels
        self.targetOutline = Self.makeOutline(for: number)
    }
}

extension LevelPack {
    private static func makeOutline(for number: Int) -> Outline {
        let radius: CGFloat = 250//10 * CGFloat(number) + 100
        let color = UIColor(hue: CGFloat(number) / 10, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let resultColor = SIMD4<UInt8>(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
        
        return Outline(radius: radius, color: resultColor)
    }
}
