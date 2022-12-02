//
//  Polygon+Init.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 14.01.2022.
//

import Foundation
import CoreGraphics
import Voronoi

extension Polygon {
    public static func make(radius: CGFloat, position: CGPoint, vertexCount: Int) -> Polygon {
        var result = Polygon()
        for i in 0 ..< vertexCount {
            let a: CGFloat = 2 * .pi * CGFloat(i) / CGFloat(vertexCount)
            let v = CGPoint(x: position.x + radius * cos(a), y: position.y + radius * sin(a))
            result.append(v)
        }
//        if let first = result.first {
//            result.append(first)
//        }
        return result
    }
    
    public static func make(from sitePoints: [CGPoint], bounds: CGRect) -> [Polygon] {
        let vpoints = sitePoints.map { SitePoint<Bool>(point: SIMD2<Double>(x: Double($0.x), y: Double($0.y)), userData: true) }
        
        let clipRect = ClipRect.minMaxXY(minX: bounds.minX,
                                         minY: bounds.minY,
                                         maxX: bounds.maxX,
                                         maxY: bounds.maxY)
        
        let voronoiResult = Voronoi.runFortunesAlgorithm(sitePoints: vpoints, clipRect: clipRect, options: [.makeSitePolygonVertices, .makeEdgesOnClipRectBorders], randomlyOffsetSiteLocationsBy: nil)
        
        let result = voronoiResult.sites.map { site -> Polygon in
            var polygon = site.polygonVertices.map { CGPoint(x: $0.x, y: $0.y) }
//            if let first = polygon.first {
//                polygon += [first]
//            }
            return polygon
        }
        return result
    }
}
