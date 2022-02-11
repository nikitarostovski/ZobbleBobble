//
//  CGFloat+Utils.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import CoreGraphics

extension CGFloat {
    var degrees: CGFloat {
        self * CGFloat(180) / .pi
    }
    
    var radians: CGFloat {
        self / CGFloat(180) * .pi
    }
    
    func randomOffset(by percent: Int) -> CGFloat {
        let r = CGFloat.random(in: -CGFloat(percent) ... CGFloat(percent))
        return self * r / 100
    }
}
