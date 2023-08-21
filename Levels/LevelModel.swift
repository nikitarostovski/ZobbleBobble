//
//  LevelModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

//public struct LevelModel: Codable {
//    /// In degrees
//    public var rotationPerSecond: CGFloat
//    public var gravityRadius: CGFloat
//
//    public var initialChunks: [ChunkModel]
//    public var missleChunks: [ChunkModel]
//
//    public var misslesBefore: Int = 0
//    public private(set) var allMaterials = [MaterialType]()
//
//    private enum CodingKeys: String, CodingKey {
//        case rotationPerSecond
//        case gravityRadius
//        case initialChunks
//        case missleChunks
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        self.initialChunks = try container.decode([ChunkModel].self, forKey: .initialChunks)
//        self.gravityRadius = try container.decode(CGFloat.self, forKey: .gravityRadius)
//        self.rotationPerSecond = try container.decode(CGFloat.self, forKey: .rotationPerSecond)
//        self.missleChunks = try container.decode([ChunkModel].self, forKey: .missleChunks)
//
//        let materials = (initialChunks + missleChunks).flatMap { $0.particles.map { $0.material } }
//        self.allMaterials = materials
//    }
//}
