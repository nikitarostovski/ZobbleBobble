//
//  Cell.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 12.04.2021.
//

import CoreGraphics

struct Cell: Codable {
    
    struct Color: Codable {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        
        static var random: Color {
            let r = CGFloat(arc4random() % 32) + 224
            let g = CGFloat(arc4random() % 32) + 224
            let b = CGFloat(arc4random() % 255)
            return Color(r: r / 255, g: g / 255, b: b / 255)
        }
    }
    
    var center: CGPoint
    var polygon: Polygon
    var color: Color
    
    init(center: CGPoint) {
        self.center = center
        self.polygon = []
        self.color = Color.random
    }
    
    func split(impulse: CGVector, point: CGPoint) -> [Cell] {
        
        // Define bounds
        
        let minX = polygon.min(by: { $0.x < $1.x })?.x ?? 0
        let minY = polygon.min(by: { $0.y < $1.y })?.y ?? 0
        let maxX = polygon.max(by: { $0.x < $1.x })?.x ?? 0
        let maxY = polygon.max(by: { $0.y < $1.y })?.y ?? 0
        
        
        let clipRect = ClipRect.minMaxXY(minX: Double(minX),
                                         minY: Double(minY),
                                         maxX: Double(maxX),
                                         maxY: Double(maxY))
        
        
        // Generate points
        
        var points = [CGPoint]()
        
        let pointStep: CGFloat = min(maxX - minX, maxY - minY) / 2
        let displacementStep: CGFloat = pointStep / 2
        
        for x in stride(from: minX, to: maxX, by: pointStep) {
            for y in stride(from: minY, to: maxY, by: pointStep) {
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
                
                points.append(CGPoint(x: newCenterX, y: newCenterY))
            }
        }
        let vpoints = points.map { SitePoint<Void>(point: SIMD2<Double>(x: Double($0.x), y: Double($0.y))) }
        
        // Apply Voronoi diagram
        
        let result = Voronoi.runFortunesAlgorithm(sitePoints: vpoints, clipRect: clipRect, options: [.makeSitePolygonVertices, .makeEdgesOnClipRectBorders], randomlyOffsetSiteLocationsBy: nil)
        let polygons = result.sites.map { site -> Polygon in
            return site.polygonVertices.map { CGPoint(x: $0.x, y: $0.y) }
        }
        
        // Clip with super polygon
        
        var clippedPolygons = [Polygon]()
        let superPolygon = self.polygon
        for polygon in polygons {
            var intersections = superPolygon.intersection(polygon)
            intersections = intersections.filter { $0.count >= 3 }
            intersections = intersections.map { $0 + [$0[0]] }
            clippedPolygons.append(contentsOf: intersections)
        }
        
        
        //        area fix needed:
        //        clippedPolygons = clippedPolygons.filter { $0.area < -50 }
        
        // Map polygons to cells
        
        var newCells = [Cell]()
        newCells = clippedPolygons.map { p in
            var cell = Cell(center: p.centroid)
            cell.polygon = p
            cell.color = self.color
            return cell
        }
        
        return newCells
    }
}
