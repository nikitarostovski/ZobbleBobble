//
//  Wall.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Wall: SKShapeNode {
    
    private var polygon: Polygon?
    
    weak var terrain: Terrain?
    
    static func make(from polygon: inout Polygon) -> Wall {
        let node = Wall(points: &polygon, count: polygon.count)
        node.polygon = polygon
        node.fillColor = UIColor.blue.withAlphaComponent(0.2)
//        let node = Wall(splinePoints: &polygon, count: polygon.count)
        node.setupPhysics(points: polygon)
        return node
    }
    
    private func setupPhysics(points: [CGPoint]) {
        guard points.count > 2 else { return }
        
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)
        body.isDynamic = false
        body.friction = 10
        
        body.categoryBitMask = Category.wall.rawValue
        body.collisionBitMask = Category.unit.rawValue | Category.wall.rawValue
        body.contactTestBitMask = Category.missle.rawValue
        
        physicsBody = body
    }
    
    public func explode(impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) {
        if physicsBody?.isDynamic ?? false { return }
        guard let terrain = terrain, let polygon = polygon else { return }
        
        let newPolygons = splitPolygon(polygon)
        
        let walls = newPolygons.map { pp -> Wall in
            var p = pp
            let wall = Self.make(from: &p)
            wall.physicsBody?.isDynamic = true
//            wall.physicsBody?.density = 0.1
            wall.fillColor = .yellow
            wall.strokeColor = .red
            return wall
        }
        
        terrain.replace(wall: self, with: walls)
        
        let imp = CGVector(dx: normal.dx * 0.1,
                           dy: normal.dy * 0.1)
        walls.forEach {
            $0.physicsBody?.applyImpulse(imp, at: contactPoint)
        }
    }
    
    public func destroy() {
        physicsBody = nil
        removeFromParent()
    }
    
    
    private func splitPolygon(_ polygon: Polygon) -> [Polygon] {
        let vpoints = polygon.map { SitePoint<Void>(point: SIMD2<Double>(x: Double($0.x), y: Double($0.y))) }
        
        let minX = polygon.min(by: { $0.x < $1.x })?.x ?? 0
        let minY = polygon.min(by: { $0.y < $1.y })?.y ?? 0
        let maxX = polygon.max(by: { $0.x < $1.x })?.x ?? 0
        let maxY = polygon.max(by: { $0.y < $1.y })?.y ?? 0
        
        
        let clipRect = ClipRect.minMaxXY(minX: Double(minX),
                                         minY: Double(minY),
                                         maxX: Double(maxX),
                                         maxY: Double(maxY))
        
        let result = Voronoi.runFortunesAlgorithm(sitePoints: vpoints, clipRect: clipRect, options: [.makeSitePolygonVertices, .makeEdgesOnClipRectBorders], randomlyOffsetSiteLocationsBy: nil)
        let polygons = result.sites.map { site -> Polygon in
            return site.polygonVertices.map { CGPoint(x: $0.x, y: $0.y) }
        }
        
        
        var clippedPolygons = [Polygon]()
        let superPolygon = self.polygon
        for polygon in polygons {
            guard let intersections  = superPolygon?.intersection(polygon) else { continue }
            clippedPolygons.append(contentsOf: intersections)
        }
        
        return clippedPolygons
    }
}
