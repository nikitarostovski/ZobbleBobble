//
//  Polygon+Utils.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 14.01.2022.
//

import Foundation
import CoreGraphics
import SwiftClipper
import Delaunay

extension Polygon {
    public func contains(point: CGPoint) -> Bool {
        contains(point: point)
    }
    
    public func intersection(with p: Polygon) -> [Polygon] {
        guard p.bounds.intersects(bounds) else { return [] }
        return intersection(p)
    }
    
    public func difference(from p: Polygon) -> [Polygon] {
        difference(p)
    }
    
    public func union(with p: Polygon) -> [Polygon] {
        union(p)
    }
    
    public func area() -> CGFloat {
        if isEmpty { return .zero }
        
        var sum: CGFloat = 0
        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }
            
            sum += point.x * nextPoint.y - nextPoint.x * point.y
        }
        
        return sum / 2
    }
    
    public func centroid() -> CGPoint {
        if isEmpty { return .zero }
        
        let area = area()
        if area == 0 { return .zero }
        
        var sumPoint: CGPoint = .zero
        
        for (index, point) in enumerated() {
            let nextPoint: CGPoint
            if index < count-1 {
                nextPoint = self[index+1]
            } else {
                nextPoint = self[0]
            }
            
            let factor = point.x * nextPoint.y - nextPoint.x * point.y
            sumPoint.x += (point.x + nextPoint.x) * factor
            sumPoint.y += (point.y + nextPoint.y) * factor
        }
        
        return sumPoint / 6 / area
    }
    
    public func mean() -> CGPoint? {
        if isEmpty { return nil }
        
        return reduce(.zero, +) / CGFloat(count)
    }
    
    public func triangulate() -> [Polygon] {
        let t = CDT()
        let points = self.map { Point(x: $0.x, y: $0.y) }
        let triangles = t.triangulate(points)
        
        return triangles.map {
            [
                CGPoint(x: CGFloat($0.point3.x), y: CGFloat($0.point3.y)),
                CGPoint(x: CGFloat($0.point2.x), y: CGFloat($0.point2.y)),
                CGPoint(x: CGFloat($0.point1.x), y: CGFloat($0.point1.y))
            ]
        }
    }
}

extension Array where Element == Polygon {
    public func convexHull() -> Polygon {
        let array = flatMap { $0 }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let lhs = (a.x - o.x) * (b.y - o.y)
            let rhs = (a.y - o.y) * (b.x - o.x)
            return lhs - rhs
        }
        // Exit early if there aren’t enough points to work with.
        guard array.count > 1 else { return [] }

        // Create storage for the lower and upper hulls.
        var lower = [CGPoint]()
        var upper = [CGPoint]()

        // Sort points in lexicographical order.
        let points = array.sorted { a, b in
            a.x < b.x || a.x == b.x && a.y < b.y
        }

        // Construct the lower hull.
        for point in points {
            while lower.count >= 2 {
                let a = lower[lower.count - 2]
                let b = lower[lower.count - 1]
                if cross(a, b, point) > 0 { break }
                lower.removeLast()
            }
            lower.append(point)
        }

        // Construct the upper hull.
        for point in points.lazy.reversed() {
            while upper.count >= 2 {
                let a = upper[upper.count - 2]
                let b = upper[upper.count - 1]
                if cross(a, b, point) > 0 { break }
                upper.removeLast()
            }
            upper.append(point)
        }

        // Remove each array’s last point, as it’s the same as the first point
        // in the opposite array, respectively.
        lower.removeLast()
        upper.removeLast()

        // Join the arrays to form the convex hull.
        return lower + upper
    }
    
    public func getDifference(from polygonsAvoiding: [Polygon]) -> [Polygon] {
        self.flatMap { p in
            polygonsAvoiding.flatMap { a in
                p.difference(from: a)
            }
        }
    }
    
    public func combine() -> [Polygon] {
//        let combination = self.flatMap { $0 }
        return self.unions().map {
            $0.triangulate()
        }
        .flatMap { $0 }
        
//        let result: Polygon = combination.convexHull()
//
//        return result.triangulate()
    }
}
