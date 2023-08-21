//
//  ChunkModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

//public struct ChunkModel: Codable {
//    @DecodableFloat
//    private var scale: CGFloat
//    @DecodableFloat
//    public var startImpulse: CGFloat
//    public let source: String?
//
//    public private(set) var particles: [ParticleModel] = []
//    public var boundingRadius: CGFloat
//
//    private enum CodingKeys: String, CodingKey {
//        case scale
//        case startImpulse
//        case source
//        case particles
//        case boundingRadius
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let source = try container.decodeIfPresent(String.self, forKey: .source)
//        self.boundingRadius = try container.decodeIfPresent(CGFloat.self, forKey: .boundingRadius) ?? 0
//        self.source = source
//        self.scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
//        self.startImpulse = try container.decodeIfPresent(CGFloat.self, forKey: .startImpulse) ?? 0
//        self.particles = try container.decodeIfPresent([ParticleModel].self, forKey: .particles) ?? []
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encodeIfPresent(startImpulse, forKey: .startImpulse)
//        try container.encodeIfPresent(particles, forKey: .particles)
//        try container.encodeIfPresent(boundingRadius, forKey: .boundingRadius)
//    }
//
//    public mutating func setParticles(_ newParticles: [ParticleModel]) {
//        let maxDist = newParticles
//            .map {
//                let point = CGPoint(x: $0.x, y: $0.y)
//                return sqrt(point.y * point.y + point.x * point.x)
//            }
//            .sorted(by: { abs($0) > abs($1) })
//            .first ?? 0
//        self.particles = newParticles
//        self.boundingRadius = abs(maxDist)
//    }
//}
