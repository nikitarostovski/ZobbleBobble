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
    func intersection(with p: Polygon) -> [Polygon] {
        guard p.bounds.intersects(bounds) else { return [] }
        return intersection(p)
    }
    
    func difference(from p: Polygon) -> [Polygon] {
        difference(p)
    }
    
    func union(with p: Polygon) -> [Polygon] {
        union(p)
    }
    
    func area() -> CGFloat {
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
    
    func centroid() -> CGPoint? {
        if isEmpty { return nil }
        
        let area = area()
        if area == 0 { return nil }
        
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
    
    func mean() -> CGPoint? {
        if isEmpty { return nil }
        
        return reduce(.zero, +) / CGFloat(count)
    }
}

extension Array where Element == Polygon {
    func getDifference(from polygonsAvoiding: [Polygon]) -> [Polygon] {
        self.flatMap { p in
            polygonsAvoiding.flatMap { a in
                p.difference(from: a)
            }
        }
    }
}
