//
//  LevelModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public struct LevelModel: Codable {
    /// In degrees
    public let rotationPerSecond: CGFloat
    public let gravityRadius: CGFloat
    public let particleRadius: CGFloat
    public let initialChunks: [ChunkModel]
    public let missles: [MissleModel]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gravityRadius = try container.decode(CGFloat.self, forKey: .gravityRadius)
        self.rotationPerSecond = try container.decode(CGFloat.self, forKey: .rotationPerSecond)
        
        let particleRadius = try container.decode(CGFloat.self, forKey: .particleRadius)
        let initialChunks = try container.decode([ChunkModel].self, forKey: .initialChunks)
        let missles = try container.decode([MissleModel].self, forKey: .missles)
        
        self.initialChunks = initialChunks.map { var c = $0; var s = c.shape; s.particleRadius = particleRadius; c.shape = s; return c }
        self.missles = missles.map { var m = $0; var s = m.shape; s.particleRadius = particleRadius; m.shape = s; return m }
        self.particleRadius = particleRadius
    }
}
