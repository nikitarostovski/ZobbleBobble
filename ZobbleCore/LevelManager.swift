//
//  LevelManager.swift
//  LevelManager
//
//  Created by Rost on 14.11.2022.
//

import UIKit

public final class LevelManager {
    public var allLevels: [Level]
    
    public let levelDistance: CGFloat
    public let levelsTotalWidth: CGFloat
    
    public init() {
        let dist: CGFloat = 500
        let levels = Array(0..<4).map { i in
            Level(number: i, center: CGPoint(x: dist * CGFloat(i), y: 0))
        }
        self.levelDistance = dist
        self.allLevels = levels
        self.levelsTotalWidth = (levels.map { $0.center.x }.max() ?? 0) + dist
    }
    
    public func getClosestLevel(to point: CGPoint) -> (Int, CGFloat) {
        var closestIndex = 0
        var closestDist = CGFloat.greatestFiniteMagnitude
        for level in allLevels {
            let dist = level.center.distance(to: point)
            if dist < closestDist {
                closestDist = dist
                closestIndex = level.number
            }
        }
//        print("\(point) \(closestIndex) \(closestDist)")
        return (closestIndex, closestDist)
    }
}
