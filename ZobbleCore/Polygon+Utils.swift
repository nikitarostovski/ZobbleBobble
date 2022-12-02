//
//  Polygon+Utils.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 14.01.2022.
//

import Foundation
import CoreGraphics
import SwiftClipper

extension Polygon {
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
}

extension Array where Element == Polygon {
    public func getDifference(from polygonsAvoiding: [Polygon]) -> [Polygon] {
        self.flatMap { p in
            polygonsAvoiding.flatMap { a in
                p.difference(from: a)
            }
        }
    }
}
