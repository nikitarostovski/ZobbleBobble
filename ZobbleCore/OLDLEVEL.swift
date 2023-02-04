////
////  Level.swift
////  LevelParser
////
////  Created by Rost on 14.11.2022.
////
//
//import Foundation
//import UIKit
//
//public class Level {
//    public struct Shape {
//        public var position: CGPoint
//        public var radius: Float
//        public var color: CGRect
//    }
//
//    public struct Outline {
//        public var radius: CGFloat
//        public var color: SIMD4<UInt8>
//    }
//
//    public let number: Int
//    public let initialShapes: [Shape]
//    public var playerShapes: [Shape]
//    public var materials: [Material]
//
//    public var targetOutline: Outline
//
//    init(number: Int, particleRadius: CGFloat) {
//        let shapes = Self.makeShapes(for: number, particleRadius: particleRadius)
//        self.number = number
//        self.initialShapes = shapes
//        self.playerShapes = shapes
//        self.targetOutline = Self.makeOutline(for: number)
//        self.materials = Self.makeMaterials(for: number)
//    }
//
//    public func addShape(position: CGPoint, radius: Float, color: CGRect) {
//        playerShapes.append(Shape(position: CGPoint(x: position.x, y: position.y), radius: radius, color: color))
//    }
//}
//
//extension Level {
//    private static func makeMaterials(for number: Int) -> [Material] {
//        if number == 0 {
//            return [.lavaRed, .lavaYellow, .lavaYellow, .lavaRed, .lavaRed, .lavaYellow, .lavaRed, .lavaYellow]
//        } else {
//            return [.lavaRed, .lavaYellow, .lavaYellow, .lavaRed, .bomb, .lavaYellow]
//        }
//        let materialCount = 2//5 + 2 * number
//
//        var result = [Material]()
//        for i in 0..<materialCount {
//            if i % 2 == 0 {
//                result.append(.lavaRed)
//            } else {
//                result.append(.lavaYellow)
//            }
//        }
//        return result
//    }
//
//    private static func makeOutline(for number: Int) -> Outline {
//        let radius = 10 * CGFloat(number) + 100
//
//        let resultColor: SIMD4<UInt8>
//        switch number % 3 {
//        case 0: resultColor = SIMD4<UInt8>(12, 22, 79, 255);
//        case 1: resultColor = SIMD4<UInt8>(186, 30, 104, 255);
//        case 2: resultColor = SIMD4<UInt8>(118, 73, 254, 255);
//        default: resultColor = SIMD4<UInt8>(255, 255, 255, 255);
//        }
//
//        return Outline(radius: radius, color: resultColor)
//    }
//
//    private static func makeShapes(for number: Int, particleRadius: CGFloat) -> [Shape] {
//        let radius: CGFloat = 10
//        let particleStride: CGFloat = particleRadius * 2 * 0.75
//
//        let aabb = CGRect(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius)
//
//        var resultPoints = [CGPoint]()
//        for y in stride(from: floor(aabb.minY / particleStride) * particleStride, to: aabb.maxY, by: particleStride) {
//            for x in stride(from: floor(aabb.minX / particleStride) * particleStride, to: aabb.maxX, by: particleStride) {
//                let point = CGPoint(x: x, y: y)
//                if point.distance(to: .zero) <= radius {
//                    resultPoints.append(point)
//                }
//            }
//        }
//
//        return resultPoints.map { Shape(position: $0, radius: Float(particleRadius), color: CGRect(x: 255, y: 255, width: 255, height: 255)) }
//    }
//}
