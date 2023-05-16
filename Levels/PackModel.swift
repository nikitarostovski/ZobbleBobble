//
//  PackModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public struct PackModel: Codable {
    public var radius: CGFloat
    public var levels: [LevelModel]
    
    public var particleRadius: CGFloat
    public var missleCount: Int
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let particleRadius = try container.decode(CGFloat.self, forKey: .particleRadius)
            var levels = try container.decode([LevelModel].self, forKey: .levels)
            self.radius = try container.decode(CGFloat.self, forKey: .radius)
            self.particleRadius = particleRadius
            
            var misslesTotal = 0
            for i in 0..<levels.count {
                levels[i].misslesBefore = misslesTotal
                levels[i].particleRadius = particleRadius
                misslesTotal += levels[i].missleChunks.count
            }
            
            self.missleCount = misslesTotal//self.levels.reduce(into: 0, { $0 += $1.missles.count })
            self.levels = levels
        } catch {
            print(error)
            throw error
        }
    }
}
