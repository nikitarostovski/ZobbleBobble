//
//  Grid.swift
//  LAIPoissonDiskSampling
//
//  Created by Anna Afanasyeva on 28/10/2016.
//  Copyright © 2016 Anna Afanasyeva. All rights reserved.
//

internal class Grid {
    private let width: Int
    private let height: Int
    private let cellSize: Double
    private var array: [[Point]]
    
    public init(width: Double, height: Double, cellSize: Double) {
        self.width = Int(ceil(width / cellSize))
        self.height = Int(ceil(height / cellSize))
        self.cellSize = cellSize
        self.array = [[Point]](repeatElement([Point](repeatElement(Point.nan, count: self.width)), count: self.height))
    }
    
    public func add(_ point: Point) {
        let gridPoint = self.gridPoint(from: point)
        self.array[gridPoint.y][gridPoint.x] = point
    }
    
    public func gridPoint(from point: Point) -> GridPoint {
        return GridPoint(x: point.x / self.cellSize, y: point.y / self.cellSize)
    }
    
    public func hasNeighbors(_ point: Point, radius: Double) -> Bool {
        let gridPoint = self.gridPoint(from: point)
        
        let neighborhood = self.mooreNeighborhood(gridPoint, range: 2)
        for _gridPoint in neighborhood {
            
            let _point = self.array[_gridPoint.y][_gridPoint.x]
            
            if !_point.isNaN() {
                if point.distance(_point) < radius {
                    return true
                }
            }
        }
        return false
    }
    
    fileprivate func mooreNeighborhood(_ gridPoint: GridPoint, range: Int) -> [GridPoint] {
        var neighborhood = [GridPoint]()
        
        for x in stride(from: gridPoint.x - range, to: gridPoint.x + range + 1, by: 1) {
            for y in stride(from: gridPoint.y - range, to: gridPoint.y + range + 1, by: 1) {
                let _gridPoint = GridPoint(x: x, y: y)
                
                if (self.isValid(_gridPoint)) {
                    neighborhood.append(_gridPoint)
                }
            }
        }
        return neighborhood
    }
    
    fileprivate func isValid(_ gridPoint: GridPoint) -> Bool {
        return !(gridPoint.x < 0 || gridPoint.x >= self.width ||
            gridPoint.y < 0 || gridPoint.y >= self.height)
    }
}
