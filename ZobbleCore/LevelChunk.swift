//
//  LevelChunk.swift
//  ZobbleCore
//
//  Created by Rost on 30.11.2022.
//

import Foundation

public struct LevelChunk {
    public struct Ground {
        public let left: CGPoint
        public let right: CGPoint
    }
    
    public let uuid = UUID()
    public let ground: [Ground]
    
    public let startPoint: CGPoint
    public let exitPoint: CGPoint
    
    public init?(ground: [Ground]) {
        guard !ground.isEmpty else { return nil }
        self.ground = ground
        self.startPoint = ground.first!.left
        self.exitPoint = ground.last!.right
    }
}
