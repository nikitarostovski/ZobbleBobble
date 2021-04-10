//
//  MatrixGenerator.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import Foundation
import CoreGraphics

typealias Matrix = [[Int]]

final class MatrixGenerator {
    
    private static func makeBox(width: Int, height: Int) -> Matrix {
        var cave = Matrix()
        for y in 0 ..< height {
            var row = [Int]()
            for x in 0 ..< width {
                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
                    row.append(0)
                } else {
                    row.append(-1)
                }
            }
            cave.append(row)
        }

        cave[1][width / 2] = 0
        
        
        cave[height / 2][width / 2] = 0
        return cave
    }
    
    
    static func generate(width: Int, height: Int, unitCount: Int, wallChance: Float) -> (Matrix, [(Int, Int)]) {
//        return (makeBox(width: width, height: height), [])
        var result = randomCave(width: width, height: height, wallChance: wallChance)
        
//        let unitPositions = spawnPoints(in: result, width: width, height: height, count: unitCount)
//        clear(matrix: &result, width: width, height: height, points: unitPositions)
        
        let smoothIterations = 2
        for _ in 0 ..< smoothIterations {
            result = smoothCave(cave: result, width: width, height: height)
        }
        sewUpCave(cave: &result, width: width, height: height)
        return (result, [])//unitPositions)
    }
    
    private static func randomCave(width: Int, height: Int, wallChance: Float) -> Matrix {
        var cave = Matrix()
        for _ in 0 ..< height {
            var row = [Int]()
            for _ in 0 ..< width {
                let raw = Float(arc4random() % 100)
                if raw > wallChance * 100 {
                    row.append(-1)
                } else {
                    row.append(0)
                }
            }
            cave.append(row)
        }
        return cave
    }
    
    private static func sewUpCave(cave: inout Matrix, width: Int, height: Int) {
        for x in 0 ..< width {
            for y in 0 ..< height {
                if x == 0 || x == width - 1 || y == 0 || y == height - 1 {
                    cave[y][x] = 0
                }
            }
        }
    }
    
    private static func smoothCave(cave: Matrix, width: Int, height: Int) -> Matrix {
        var cave = cave
        let wallThreshold = 4
        
        for x in 0 ..< width {
            for y in 0 ..< height {
                let cell = cave[y][x]
                
                if y == 0 || x == 0 || y == height - 1 || x == width - 1 {
                    continue
                }
                
                var wallsAround = 0
                
                for mooreX in x - 1 ... x + 1 {
                    guard mooreX >= 0, mooreX < width else { continue }
                    for mooreY in y - 1 ... y + 1 {
                        guard mooreY >= 0, mooreY < height else { continue }
                        
                        if mooreX == x && mooreY == y { continue }
                        
                        if cave[mooreY][mooreX] >= 0 {
                            wallsAround += 1
                        }
                    }
                }
                
                if wallsAround == 8 {
                    cave[y][x] = 0
                } else if wallsAround == 0 {
                    cave[y][x] = -1
                } else {
                    switch cell {
                    case 0:
                        if wallsAround >= wallThreshold + 1 {
                            cave[y][x] = 0
                        } else {
                            cave[y][x] = -1
                        }
                        
                    default:
                        if wallsAround >= wallThreshold {
                            cave[y][x] = 0
                        } else {
                            cave[y][x] = -1
                        }
                    }
                }
            }
        }
        return cave
    }
    
    // MARK: - Spawn points
    
//    private static func spawnPoints(in matrix: Matrix, width: Int, height: Int, count: Int) -> [(Int, Int)] {
//        let centerX = width / 2
//        let centerY = height / 2
//        let distance = min(CGFloat(width), CGFloat(height)) / 3
//
//        var result = [(Int, Int)]()
//        for i in 0 ..< count {
//            let angleDegrees = CGFloat(i) / CGFloat(count) * 360
//            let angleRadians = angleDegrees * .pi / 180
//
//
//            let x = centerX + Int(distance * cos(angleRadians))
//            let y = centerY + Int(distance * sin(angleRadians))
//            result.append((x, y))
//        }
//        return result
//    }
//
//    private static func clear(matrix: inout Matrix, size: Int, points: [(Int, Int)]) {
//        let clearRadius = 2
//
//        points.forEach { point in
//            for y in (point.1 - clearRadius) ... (point.1 + clearRadius) {
//                guard y >= 0, y < size else { continue }
//                for x in (point.0 - clearRadius) ... (point.0 + clearRadius) {
//                    guard x >= 0, x < size else { continue }
//                    matrix[y][x] = -1
//                }
//            }
//        }
//    }
}
