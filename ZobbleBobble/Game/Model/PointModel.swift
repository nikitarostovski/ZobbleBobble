//
//  PointModel.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import Foundation

class PointModel: Equatable {
    
    var x: Float
    var y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    static func == (lhs: PointModel, rhs: PointModel) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}
