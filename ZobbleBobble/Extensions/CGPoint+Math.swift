//
//  CGPoint+Math.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 14.11.2020.
//

import CoreGraphics

extension CGFloat {
    
    var degrees: CGFloat {
        return self * CGFloat(180) / .pi
    }
    
    var radians: CGFloat {
        return self / CGFloat(180) * .pi
    }
}

extension CGPoint {
    
    func distance(to: CGPoint) -> CGFloat {
        return sqrt((x - to.x) * (x - to.x) + (y - to.y) * (y - to.y))
    }
    
    func angle(to comparisonPoint: CGPoint) -> CGFloat {
        let originX = comparisonPoint.x - x
        let originY = comparisonPoint.y - y
        var bearingRadians = CGFloat(atan2f(Float(originY), Float(originX)))
        
        while bearingRadians < 0 {
            bearingRadians += 2 * .pi
        }

        return bearingRadians
    }
}
