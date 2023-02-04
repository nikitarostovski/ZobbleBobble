//
//  PackModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public struct PackModel: Codable {
    public let radius: CGFloat
    public let levels: [LevelModel]
    
    public let missleCount: Int
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.radius = try container.decode(CGFloat.self, forKey: .radius)
        self.levels = try container.decode([LevelModel].self, forKey: .levels)
        
        self.missleCount = self.levels.reduce(into: 0, { $0 += $1.missles.count })
    }
}
