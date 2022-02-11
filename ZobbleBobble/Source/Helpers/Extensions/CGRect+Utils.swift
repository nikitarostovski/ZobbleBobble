//
//  CGRect+Utils.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 26.12.2021.
//

import CoreGraphics

extension CGRect {
    func randomPoint() -> CGPoint {
        CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.width))) + origin.x,
                y: CGFloat(arc4random_uniform(UInt32(self.height))) + origin.y)
    }
}
