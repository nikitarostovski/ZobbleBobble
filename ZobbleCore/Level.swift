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
    public let initialShapes: [Shape]
    public var playerShapes: [Shape]
    
    public var targetOutline: Outline
    
    init(number: Int) {
        let shapes = Self.makeShapes(for: number)
        self.number = number
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
//        let color = UIColor(hue: CGFloat(number) / 10, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
//        var r: CGFloat = 0
//        var g: CGFloat = 0
//        var b: CGFloat = 0
//        var a: CGFloat = 0
//        color.getRed(&r, green: &g, blue: &b, alpha: &a)
//        let resultColor = SIMD4<UInt8>(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
        
        
//        float3 darkBlue = float3(12.0/255.0, 22.0/255.0, 79.0/255.0);
//        float3 pink = float3(186.0/255.0, 30.0/255.0, 104.0/255.0);
//        float3 lavanda = float3(118.0/255.0, 73.0/255.0, 254.0/255.0);
        
        let resultColor: SIMD4<UInt8>
        switch number % 3 {
        case 0: resultColor = SIMD4<UInt8>(12, 22, 79, 255);
        case 1: resultColor = SIMD4<UInt8>(186, 30, 104, 255);
        case 2: resultColor = SIMD4<UInt8>(118, 73, 254, 255);
        default: resultColor = SIMD4<UInt8>(255, 255, 255, 255);
        }
        
        return Outline(radius: radius, color: resultColor)
    }
    
    private static func makeShapes(for number: Int) -> [Shape] {
        let particleRadius: CGFloat = 2.5
        let radius: CGFloat = 10
        let particleStride: CGFloat = particleRadius * 2 * 0.75
        
        let aabb = CGRect(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius)
        
        var resultPoints = [CGPoint]()
        for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
            for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
                let point = CGPoint(x: x, y: y)
                if point.distance(to: .zero) <= radius {
                    resultPoints.append(point)
                }
            }
        }
        
        return resultPoints.map { Shape(position: $0, radius: Float(particleRadius), color: CGRect(x: 255, y: 255, width: 255, height: 255)) }
    }
}
