//
//  Level.swift
//  LevelParser
//
//  Created by Rost on 14.11.2022.
//

import Foundation
import UIKit

public class Level {
    public struct Shape {
        public var position: CGPoint
        public var radius: Float
        public var color: CGRect
    }
    
    public struct Outline {
        public var radius: CGFloat
        public var color: SIMD4<UInt8>
    }
    
    public let number: Int
    public let center: CGPoint
    public let initialShapes: [Shape]
    public var playerShapes: [Shape]
    
    public var targetOutline: Outline
    
    init(number: Int, center: CGPoint) {
        let shapes = Self.makeShapes(for: number, center: center)
        self.number = number
        self.center = center
        self.initialShapes = shapes
        self.playerShapes = shapes
        self.targetOutline = Self.makeOutline(for: number)
    }
    
    public func addShape(position: CGPoint, radius: Float, color: CGRect) {
        playerShapes.append(Shape(position: CGPoint(x: position.x, y: position.y), radius: radius, color: color))
    }
}

extension Level {
    private static func makeOutline(for number: Int) -> Outline {
        let radius = 10 * CGFloat(number) + 100
        let color = UIColor(hue: CGFloat(number) / 10, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let resultColor = SIMD4<UInt8>(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
        return Outline(radius: radius, color: resultColor)
    }
    
    private static func makeShapes(for number: Int, center: CGPoint) -> [Shape] {
        return [
            center
        ]
            .map { Shape(position: $0, radius: 20, color: CGRect(x: 255, y: 255, width: 255, height: 255)) }
    }
}
