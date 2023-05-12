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
    
    private let initialChunks: [ChunkModel]
    private let initialMissles: [MissleModel]
    
    public var chunks: [ChunkModel] = []
    public var missles: [MissleModel] = []
    
    public var particleRadius: CGFloat = 0 {
        didSet {
            self.chunks = initialChunks.map { var c = $0; var s = c.shape; s.particleRadius = particleRadius; c.shape = s; return c }
            self.missles = initialMissles.map { var m = $0; var s = m.shape; s.particleRadius = particleRadius; m.shape = s; return m }
        }
    }
    public var misslesBefore: Int = 0
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gravityRadius = try container.decode(CGFloat.self, forKey: .gravityRadius)
        self.rotationPerSecond = try container.decode(CGFloat.self, forKey: .rotationPerSecond)
        
        self.initialChunks = try container.decode([ChunkModel].self, forKey: .initialChunks)
        self.initialMissles = try container.decode([MissleModel].self, forKey: .missles)
        
        self.chunks = []
        self.missles = []
    }
}
