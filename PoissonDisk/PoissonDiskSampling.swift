//
//  PoissonDiskSampling.swift
//  LAIPoissonDiskSampling
//
//  Created by Anna Afanasyeva on 28/10/2016.
//  Copyright © 2016 Anna Afanasyeva. All rights reserved.
//

import Darwin

open class PoissonDiskSampling {
    
    public init() { }
    
    open func generate(_ width: Double, height: Double, minDistance: Double, newPointsCount: Int) -> [Point]? {
        var processArray: [Point] = [Point]()
        var outputArray: [Point] = [Point]()
        
        let cellSize = minDistance / sqrt(2.0)
        let grid = Grid(width: width, height: height, cellSize: cellSize)
        
        let firstPoint = self.randomPoint(in: width, height: height)
        processArray.append(firstPoint)
        outputArray.append(firstPoint)
        grid.add(firstPoint)
        
        while !processArray.isEmpty {
            if let point = processArray.popRandom() {
                
                for _ in stride(from: 0, to: newPointsCount, by: 1) {
                    let newPoint = self.randomPoint(around: point, minDistance: minDistance)
                    
                    if newPoint.isInRect(width, height: height) && !(grid.hasNeighbors(newPoint, radius: minDistance)) {
                        processArray.append(newPoint)
                        outputArray.append(newPoint)
                        grid.add(newPoint)
                        continue
                    }
                }
            }
        }
        
        return outputArray
    }
    
    fileprivate func randomPoint(in width: Double, height: Double) -> Point {
        let x = Double.random(0, width)
        let y = Double.random(0, height)
        return Point(x: x, y: y)
    }
    
    fileprivate func randomPoint(around point: Point, minDistance: Double) -> Point {
        let r1 = Double.random()
        let r2 = Double.random()
        
        let radius = minDistance * (r1 + 1.0)
        let angle = 2 * .pi * r2
        
        let x = point.x + radius * cos(angle)
        let y = point.y + radius * sin(angle)
        
        return Point(x: x, y: y)
    }
}

// MARK: - Extensions

extension Array {
    mutating func popRandom() -> Element? {
        if isEmpty { return nil }
        
        let index = Int(arc4random_uniform(UInt32(count)))
        let element = self[index]
        remove(at: index)
        return element
    }
}

extension Double {
    static func random() -> Double {
        return Double(arc4random()) / 0xFFFFffff
    }
    
    static func random(_ min: Double, _ max: Double) -> Double {
        return Double.random() * (max - min) + min
    }
}
