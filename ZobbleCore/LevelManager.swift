//
//  LevelManager.swift
//  LevelManager
//
//  Created by Rost on 14.11.2022.
//

import UIKit

public final class LevelManager {
    private let packCount = 3
    private let levelCount = 10
    
    private let particleRadius: CGFloat
    
    public lazy var allLevelPacks: [LevelPack] = {
        return Array(0..<packCount).map { packIndex in
            let levels = Array(0..<levelCount).map { Level(number: $0, particleRadius: particleRadius) }
            return LevelPack(number: packIndex, levels: levels)
        }
    }()
    
    public init(particleRadius: CGFloat) {
        self.particleRadius = particleRadius
    }
//
//    public func getWidthOf(pack: Int) -> CGFloat {
//        (allLevelPacks[pack].levels.map { $0.center.x }.max() ?? 0) + levelDistance
//    }
//
//    public func getClosestLevel(to point: CGPoint, inPack index: Int) -> (Int, CGFloat) {
//        var closestIndex = 0
//        var closestDist = CGFloat.greatestFiniteMagnitude
//        for level in allLevelPacks[index].levels {
//            let dist = level.center.distance(to: point)
//            if dist < closestDist {
//                closestDist = dist
//                closestIndex = level.number
//            }
//        }
//        return (closestIndex, closestDist)
//    }
//
//    public func getClosestLevelPack(to point: CGPoint) -> (Int, CGFloat) {
//        var closestIndex = 0
//        var closestDist = CGFloat.greatestFiniteMagnitude
//        for pack in allLevelPacks {
//            let dist = pack.center.distance(to: point)
//            if dist < closestDist {
//                closestDist = dist
//                closestIndex = pack.number
//            }
//        }
//        return (closestIndex, closestDist)
//    }
}
