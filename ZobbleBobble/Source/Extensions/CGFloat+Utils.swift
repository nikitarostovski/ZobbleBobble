//
//  CGFloat+Utils.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import CoreGraphics

extension CGFloat {
    public var degrees: CGFloat {
        self * CGFloat(180) / .pi
    }
    
    public var radians: CGFloat {
        self / CGFloat(180) * .pi
    }
    
    public func randomOffset(by percent: Int) -> CGFloat {
        let r = CGFloat.random(in: -CGFloat(percent) ... CGFloat(percent))
        return self * r / 100
    }
    
    /// Gets two circles data. Returns angle from centers line to line between first circle center and an intersection point
    /// - Parameters:
    ///   - r1: first circle radius
    ///   - r2: second circle radius
    ///   - d: distance between circle centers
    /// - Returns: an angle in radians
    public static func circleIntersectionAngle(r1: CGFloat, r2: CGFloat, d: CGFloat) -> CGFloat {
        if r1 + r2 < d { return 0 }
        let value = (r1 * r1 + d * d - r2 * r2) / (2 * d * r1)
        if value.isNaN { return 0 }
        let result = acos(value)
        if result.isNaN { return 0 }
        return result
    }
}
