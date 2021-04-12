//
//  MapGenerator.swift
//  LevelDesign
//
//  Created by Никита Ростовский on 12.04.2021.
//

import Foundation

final class MapGenerator {
    
    static func make(width: Int, height: Int, unitCount: Int, wallChance: Float) -> [Polygon] {
        
        let displacementStep: CGFloat = 0.4
        
        let matrix = MatrixGenerator.generate(width: width, height: height, unitCount: unitCount, wallChance: wallChance).0
        
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
        
        
        
        
        var displacedPoints = [(Bool, CGPoint)]()
        for y in 0 ..< height {
            for x in 0 ..< width {
                let point = cave[y][x]
                
                let xmin: CGFloat = CGFloat(x) - displacementStep
                let ymin: CGFloat = CGFloat(y) - displacementStep
                let xmax: CGFloat = CGFloat(x) + displacementStep
                let ymax: CGFloat = CGFloat(y) + displacementStep
                
                let stepX = xmax - xmin
                let stepY = ymax - ymin
                
                let dx: CGFloat = CGFloat(arc4random() % UInt32(stepX * 100)) / 100
                let dy: CGFloat = CGFloat(arc4random() % UInt32(stepY * 100)) / 100
                
                let newCenterX = xmin + dx
                let newCenterY = ymin + dy
                let newCenter = CGPoint(x: newCenterX, y: newCenterY)
                
                let isWall = point >= 0
                displacedPoints.append((isWall, newCenter))
            }
        }
        
        let vpoints = displacedPoints.map { SitePoint<Bool>(point: SIMD2<Double>(x: Double($0.1.x), y: Double($0.1.y)), userData: $0.0) }
        
        
        let clipRect = ClipRect.minMaxXY(minX: Double(0),
                                         minY: Double(0),
                                         maxX: Double(width),
                                         maxY: Double(height))
        
        let result = Voronoi.runFortunesAlgorithm(sitePoints: vpoints, clipRect: clipRect, options: [.makeSitePolygonVertices, .makeEdgesOnClipRectBorders], randomlyOffsetSiteLocationsBy: nil)
        let polygons = result.sites.compactMap { site -> Polygon? in
            if site.userData == true {
                return site.polygonVertices.map { CGPoint(x: $0.x, y: $0.y) }
            }
            return nil
        }
        
        return polygons
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
