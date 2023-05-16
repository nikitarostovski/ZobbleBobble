//
//  ChunkModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public struct ChunkModel: Codable {
    @DecodableFloat
    private var scale: CGFloat
    @DecodableFloat
    public var startImpulse: CGFloat
    public let source: String?
    
    public private(set) var particles: [ParticleModel] = []
    public private(set) var boundingRadius: CGFloat = 0
    
    private enum CodingKeys: String, CodingKey {
        case scale
        case startImpulse
        case source
        case particles
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let source = try container.decodeIfPresent(String.self, forKey: .source)
        self.source = source
        self.scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
        self.startImpulse = try container.decodeIfPresent(CGFloat.self, forKey: .startImpulse) ?? 0
        self.particles = try container.decodeIfPresent([ParticleModel].self, forKey: .particles) ?? []
//        print(particles.count)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encodeIfPresent(scale, forKey: .scale)
        try container.encodeIfPresent(startImpulse, forKey: .startImpulse)
        try container.encodeIfPresent(particles, forKey: .particles)
    }
    
    public mutating func setParticles(_ newParticles: [ParticleModel]) {
        self.particles = newParticles
    }
}
