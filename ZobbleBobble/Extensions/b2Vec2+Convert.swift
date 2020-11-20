//
//  b2Vec2+Convert.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 16.11.2020.
//

import CoreGraphics
import Box2D

extension b2Vec2 {
    
    var cgPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    init(cgPoint: CGPoint) {
        self.init(b2Float(cgPoint.x), b2Float(cgPoint.y))
    }
    
    init(cgVector: CGVector) {
        self.init(b2Float(cgVector.dx), b2Float(cgVector.dy))
    }
}
