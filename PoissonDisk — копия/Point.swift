//
//  Point.swift
//  LAIPoissonDiskSampling
//
//  Created by Anna Afanasyeva on 28/10/2016.
//  Copyright © 2016 Anna Afanasyeva. All rights reserved.
//

public struct Point { // Position on the screen.
    
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public func distance(_ point: Point) -> Double {
        return sqrt(pow((x - point.x), 2) + pow((y - point.y), 2))
    }
    
    public func isInRect(_ width: Double, height: Double) -> Bool {
        return !(x < 0 || x >= width || y < 0 || y >= height)
    }
    
    public func isNaN() -> Bool {
        return x.isNaN || y.isNaN
    }
    
    public static var nan: Point {
        get {
            return Point(x: Double.nan, y: Double.nan)
        }
    }
}
