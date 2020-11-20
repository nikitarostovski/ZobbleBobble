//
//  ChunkMap.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import Foundation
import CoreGraphics

final class ChunkMap {
    
    var visibleChunks: [ChunkModel]
    
    init() {
        self.visibleChunks = []
    }
    
    func updateChunksIfNeeded(position: CGPoint, viewport: CGSize) -> (toRemove: [ChunkModel], toAdd: [ChunkModel]) {
//        print("___")
        let width = viewport.width
        let height = viewport.height
        
        let visibleFrame = CGRect(x: position.x - width / 2, y: position.y - height / 2, width: width, height: height)
        
        // Remove invisible
        let toRemove = visibleChunks.filter { chunk in
            let chunkFrame = CGRect(x: CGFloat(chunk.position.x),
                                    y: CGFloat(chunk.position.y),
                                    width: CGFloat(ChunkModel.size),
                                    height: CGFloat(ChunkModel.size))
            return !chunkFrame.intersects(visibleFrame) && !chunkFrame.contains(visibleFrame) && !visibleFrame.contains(chunkFrame)
        }
//        toRemove.forEach { print("removing chunk at \($0.position.x) \($0.position.y)") }
        visibleChunks = visibleChunks.filter { c in
            !toRemove.contains(where: { $0.position == c.position })
        }
        
        // Add new
        let toAdd = getInvisibleChunks(viewport: visibleFrame)
        visibleChunks.append(contentsOf: toAdd)
        
//        print("total: \(visibleChunks.count); added: \(toAdd.count); removed: \(toRemove.count)")
        
        return (toRemove, toAdd)
    }
    
    private func getInvisibleChunks(viewport: CGRect) -> [ChunkModel] {
        var result = [ChunkModel]()
        
        let left = Int(viewport.minX)
        let top = Int(viewport.minY)
        let bottom = Int(viewport.maxY)
        let right = Int(viewport.maxX)

        let clampedLeft = (left / Int(ChunkModel.size)) + (left < 0 ? -1 : 0)
        let clampedTop = (top / Int(ChunkModel.size)) + (top < 0 ? -1 : 0)
        let clampedBottom = (bottom / Int(ChunkModel.size)) + (bottom < 0 ? -1 : 0)
        let clampedRight = (right / Int(ChunkModel.size)) + (right < 0 ? -1 : 0)
        
        for x in clampedLeft ... clampedRight {
            for y in clampedTop ... clampedBottom {

                let containsCondition: (ChunkModel) -> Bool = { Int($0.position.x) == x * Int(ChunkModel.size) && Int($0.position.y) == y * Int(ChunkModel.size) }
                
                let pos = PointModel(x: Float(x) * ChunkModel.size,
                                     y: Float(y) * ChunkModel.size)
                
                
                if visibleChunks.first(where: containsCondition) == nil {
                    let chunk = ChunkModel.generateChunk(at: pos)
                    result.append(chunk)
                }
            }
        }
        return result
    }
}
