//
//  PolygonConverter.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import Foundation
import CoreGraphics

final class PolygonConverter {
    
    static func makeRects(from matrix: Matrix, width: Int, height: Int) -> [Polygon] {
        return makeRectWalls(from: matrix, width: width, height: height)
    }
    
    static func makePolygons(from matrix: Matrix, width: Int, height: Int) -> [Polygon] {
        return makePolygonWalls(from: matrix, width: width, height: height)
    }
    
    // MARK: - Private
    
    // MARK: Rect
    
    private static func makeRectWalls(from matrix: Matrix, width: Int, height: Int) -> [Polygon] {
        var walls = [Polygon]()
        for y in 0 ..< height {
            for x in 0 ..< width {
                guard matrix[y][x] >= 0 else { continue }
                let polygon: Polygon = [
                    CGPoint(x: CGFloat(x), y: CGFloat(y)),
                    CGPoint(x: CGFloat(x) + 1, y: CGFloat(y)),
                    CGPoint(x: CGFloat(x) + 1, y: CGFloat(y) + 1),
                    CGPoint(x: CGFloat(x), y: CGFloat(y) + 1)
                ]
                let normalizedPolygon = polygon.map { CGPoint(x: $0.x / CGFloat(width), y: $0.y / CGFloat(height)) }
                walls.append(normalizedPolygon)
            }
        }
        
        return walls
    }
    
    // MARK: Polygon
    
    private static func makePolygonWalls(from matrix: Matrix, width: Int, height: Int) -> [Polygon] {
        var id = 1
        var cave = matrix
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                let wallId = cave[y][x]
                guard wallId == 0 else { continue }
                
                cave = floodFill(x: x, y: y, cave: cave, width: width, height: height, id: id)
                id += 1
            }
        }
        
        var islands = [[(value: Int, x: Int, y: Int)]]()
        
        for i in 1 ..< id {
            var island = [(value: Int, x: Int, y: Int)]()
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let id = cave[y][x]
                    guard id == i else { continue }
                    
                    var emptyNeighbors = 0
                    
                    if y - 1 >= 0, cave[y - 1][x] < 0 {
                        emptyNeighbors += 1
                    }
                    if y + 1 < height, cave[y + 1][x] < 0 {
                        emptyNeighbors += 1
                    }
                    if x - 1 >= 0, cave[y][x - 1] < 0 {
                        emptyNeighbors += 1
                    }
                    if x + 1 < width, cave[y][x + 1] < 0 {
                        emptyNeighbors += 1
                    }
                    
                    if emptyNeighbors > 0 {
                        island.append((value: id, x: x, y: y))
                    }
                }
            }
            if island.count > 2 {
                islands.append(island)
            }
        }
        
        var walls = [Polygon]()
        for island in islands {
            guard island.count > 0 else { continue }
            var polygon: Polygon
            if false, let first = island.first {
                polygon = [
                    CGPoint(x: CGFloat(first.x), y: CGFloat(first.y)),
                    CGPoint(x: CGFloat(first.x) + 1, y: CGFloat(first.y)),
                    CGPoint(x: CGFloat(first.x) + 1, y: CGFloat(first.y) + 1),
                    CGPoint(x: CGFloat(first.x), y: CGFloat(first.y) + 1)
                ]
            } else {
                polygon = island.map { CGPoint(x: $0.x, y: $0.y) }
            }
            polygon = polygon.map { CGPoint(x: $0.x / CGFloat(width), y: $0.y / CGFloat(height)) }
            walls.append(polygon)
            
            
//            island.forEach {
//                var points = Polygon()
//                points.append(contentsOf: [
//                    CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)),
//                    CGPoint(x: CGFloat($0.x) + 1, y: CGFloat($0.y)),
//                    CGPoint(x: CGFloat($0.x) + 1, y: CGFloat($0.y) + 1),
//                    CGPoint(x: CGFloat($0.x), y: CGFloat($0.y) + 1)
//                ])
//
//                points = points.map { CGPoint(x: $0.x / CGFloat(width), y: $0.y / CGFloat(height)) }
//                walls.append(points)
//            }
            
//            points = getBoudns(of: points)
//            let polygons = getTriangles(of: points)
//            points = polygons.flatMap { $0 }
        }
        return walls
    }
    
    private static func getTriangles(of polygon: Polygon) -> [Polygon] {
        var result = [Polygon]()
        let triangles = triangulate(polygon.map { Point(x: Double($0.x), y: Double($0.y)) })
        for triangle in triangles {
            let points: Polygon = [
                triangle.point1,
                triangle.point2,
                triangle.point3
            ].map { CGPoint(x: $0.x, y: $0.y) }
            result.append(points)
        }
        return result
    }
    
    private static func getBoudns(of polygon: Polygon) -> Polygon {
        return ConvexHull().quickHull(points: polygon)
    }
    
    private static func floodFill(x: Int, y: Int, cave: Matrix, width: Int, height: Int, id: Int) -> Matrix {
        var cave = cave
        guard y >= 0, y < height else { return cave }
        guard x >= 0, x < width else { return cave }
        let cell = cave[y][x]
        
        guard cell == 0 else { return cave }
        
        cave[y][x] = id
        
        cave = floodFill(x: x + 1, y: y, cave: cave, width: width, height: height, id: id)
        cave = floodFill(x: x - 1, y: y, cave: cave, width: width, height: height, id: id)
        cave = floodFill(x: x, y: y + 1, cave: cave, width: width, height: height, id: id)
        cave = floodFill(x: x, y: y - 1, cave: cave, width: width, height: height, id: id)
        
        return cave
    }
}
