//
//  LevelChunkStorage.swift
//  ZobbleCore
//
//  Created by Rost on 30.11.2022.
//

import Foundation

final class LevelChunkStorage {
    private var chunkSize: CGFloat
    private var allChunks = [LevelChunk]()
    
    private var viewport: ClosedRange<CGFloat> = 0...0
    private var lastUpdateVisiblePositions: ClosedRange<Int> = 0...0
    
    private var visiblePositions: ClosedRange<Int> {
        let lo = Int(viewport.lowerBound / chunkSize)
        let hi = Int(viewport.upperBound / chunkSize)
        return max(0, lo) ... max(0, hi)
    }

    var visibleChunks = [LevelChunk]()
    
    init(chunkSize: CGFloat) {
        self.chunkSize = chunkSize
    }
    
    func performedUpdateForNewViewport(_ newViewPort: ClosedRange<CGFloat>) -> Bool {
        self.viewport = newViewPort
        return generateChunksIfNeeded()
    }
    
    private func generateChunksIfNeeded() -> Bool {
        let visiblePositions = visiblePositions
        guard lastUpdateVisiblePositions != visiblePositions else { return false }
        
        lastUpdateVisiblePositions = visiblePositions
        
        var didUpdateChunks = false
        while visiblePositions.upperBound >= allChunks.count {
            didUpdateChunks = true
            if let chunk = makeChunk(for: allChunks.count) {
                allChunks.append(chunk)
            }
        }
        
        visibleChunks = Array(allChunks[visiblePositions])
        
        return didUpdateChunks
    }
    
    private func makeChunk(for i: Int) -> LevelChunk? {
        var previousChunk: LevelChunk?
        if i > 0, i <= allChunks.count {
            previousChunk = allChunks[i - 1]
        }
        let startHeight = previousChunk?.exitPoint.y ?? 0
        let exitHeight = startHeight - CGFloat.random(in: chunkSize...2 * chunkSize)
        
        let left = CGFloat(i) * chunkSize
        let topLeft = startHeight
        let topRight = exitHeight
        let right = CGFloat(i + 1) * chunkSize
        
        let chunk = LevelChunk(ground: [.init(left: CGPoint(x: left, y: topLeft), right: CGPoint(x: right, y: topRight))])
        return chunk
    }
}
