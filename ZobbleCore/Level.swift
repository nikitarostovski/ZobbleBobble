//
//  Level.swift
//  LevelParser
//
//  Created by Rost on 14.11.2022.
//

import Foundation

public class Level {
    private let chunkStorage: LevelChunkStorage
    
    public var visibleChunks: [LevelChunk] {
        chunkStorage.visibleChunks
    }
    
    init() {
        self.chunkStorage = LevelChunkStorage(chunkSize: 10)
    }
    
    public func performUpdateForNewViewport(newCenter: CGPoint, newSize: CGSize) -> Bool {
        let viewportLeft = newCenter.x - newSize.width / 2
        let viewportRight = newCenter.x + newSize.width / 2
        
        return chunkStorage.performedUpdateForNewViewport(viewportLeft ... viewportRight)
    }
}
