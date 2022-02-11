//
//  GridPoint.swift
//  LAIPoissonDiskSampling
//
//  Created by Anna Afanasyeva on 28/10/2016.
//  Copyright © 2016 Anna Afanasyeva. All rights reserved.
//

internal struct GridPoint { // Coordinate on the grid.
    
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public init(x: Double, y: Double) {
        self.x = Int(x)
        self.y = Int(y)
    }
}
