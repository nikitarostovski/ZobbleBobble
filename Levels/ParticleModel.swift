//
//  ParticleModel.swift
//  ZobbleCore
//
//  Created by Rost on 13.05.2023.
//

import Foundation

//public struct ParticleModel: Codable {
//    public let x: CGFloat
//    public let y: CGFloat
//    public let material: MaterialType
//
//    public var position: CGPoint { CGPoint(x: x, y: y) }
//
//    public let movementColor: SIMD4<UInt8>
//
//    private static func generateMovementColor(for color: SIMD4<UInt8>) -> SIMD4<UInt8> {
//        var color = color
//        color.z = 0
//        if Bool.random() {
//            color.x = .random(in: 0...255)
//            color.y = 0
//        } else {
//            color.y = .random(in: 0...255)
//            color.x = 0
//        }
//        return color
//    }
//
//    public init(position: CGPoint, material: MaterialType) {
//        self.x = position.x
//        self.y = position.y
//        self.material = material
//        self.movementColor = Self.generateMovementColor(for: material.color)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let x = try container.decode(CGFloat.self, forKey: .x)
//        let y = try container.decode(CGFloat.self, forKey: .y)
//        let material = try container.decode(MaterialType.self, forKey: .material)
//
//        self.init(position: CGPoint(x: x, y: y), material: material)
//    }
//}
