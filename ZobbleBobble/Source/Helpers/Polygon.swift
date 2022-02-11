//
//  Polygon.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 25.12.2021.
//

import UIKit
import PoissonDisk

typealias Polygon = [CGPoint]

extension Polygon {
    var bounds: CGRect {
        self.reduce(CGRect.null) { rect, point in
            return rect.union(CGRect(origin: point, size: .zero))
        }
    }
    
    func destruct(impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) -> [Polygon] {
        var points = generatePointsPoissonDisk(count: 100, minDistance: Const.chunkSplitMinDistance)
        
        let maxDist: CGFloat = 100
        points = points.map { p in
            let dist = p.distance(to: contactPoint)
            let k = dist / maxDist
            return CGPoint(x: k, y: k).lerp(min: p, max: contactPoint)
        }
        let result = Polygon.make(from: points, bounds: bounds)
        return result.flatMap { $0.intersection(with: self) }
    }
    
    func split(minDistance: CGFloat = Const.chunkSplitMinDistance) -> [Polygon] {
        let points = generatePointsPoissonDisk(count: 16, minDistance: minDistance)
        let result = Polygon.make(from: points, bounds: bounds)
        return result.flatMap { $0.intersection(with: self) }
    }
}

// MARK: - Point generation

extension Polygon {
    /// Generates points using poisson disk algorithm
    /// - Parameters:
    ///   - count: Desired point amount
    ///   - minDistance: minimal available distance between points
    /// - Returns: array of randomly distributed points
    private func generatePointsPoissonDisk(count: Int, minDistance: CGFloat) -> [CGPoint] {
        let bounds = self.bounds
        let sampler = PoissonDiskSampling()
        let result = sampler.generate(bounds.width, height: bounds.height, minDistance: minDistance, newPointsCount: count)
        
        return result?.map { CGPoint(x: $0.x + bounds.minX, y: $0.y + bounds.minY) } ?? []
    }
    
    /// Generates points inside bounds, where each point is randomly selected from everey 'cell' in the grid
    /// - Parameter count: desired point count
    /// - Returns: array of points [0 ... count]
    private func generatePointsJittered(count: Int) -> [CGPoint] {
        let step: CGFloat = bounds.width / 2
        let displacementPercent = 35
        
        var result = [CGPoint]()
        for y in stride(from: bounds.minY, to: bounds.maxY, by: step) {
            for x in stride(from: bounds.minX, to: bounds.maxX, by: step) {
                let p = CGPoint(x: x + step.randomOffset(by: displacementPercent),
                                y: y + step.randomOffset(by: displacementPercent))
                result.append(p)
            }
        }
        return result
    }
}
