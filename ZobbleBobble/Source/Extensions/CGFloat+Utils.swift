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
}
