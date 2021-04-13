//
//  Wall.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Wall: SKShapeNode {
    
    private var cell: Cell?
    
    weak var terrain: Terrain?
    
    static func make(from cell: Cell) -> Wall {
        var p = cell.polygon
        let node = Wall(points: &p, count: cell.polygon.count)
        node.cell = cell
        node.fillColor = UIColor(red: cell.color.r, green: cell.color.g, blue: cell.color.b, alpha: 0.5)
//        let node = Wall(splinePoints: &polygon, count: polygon.count)
        node.setupPhysics(points: p)
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
    
    func startMonitoring() {
        let timer = Timer.init(timeInterval: 0.5, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            
            func speed(_ velocity: CGVector) -> CGFloat {
                let dx = CGFloat(velocity.dx)
                let dy = CGFloat(velocity.dy)
                return sqrt(dx*dx+dy*dy)
            }

            func angularSpeed(_ velocity: CGFloat) -> CGFloat {
                return abs(CGFloat(velocity))
            }
            
            func stop() {
                timer.invalidate()
            }
            
            guard self.physicsBody != nil else { stop(); return }
            
            let smallValue: CGFloat = 0.1
            
            let isResting = (speed(self.physicsBody!.velocity) < smallValue
                                && angularSpeed(self.physicsBody!.angularVelocity) < smallValue)
            
            if isResting {
                self.physicsBody!.isDynamic = false
                self.strokeColor = .white
                stop()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    public func explode(impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) {
        if physicsBody?.isDynamic ?? false { return }
        guard let terrain = terrain, let polygon = cell?.polygon else { return }
        
        let newPolygons = splitPolygon(polygon)
        
        let walls = newPolygons.map { p -> Wall in
            
            var cell = Cell(center: p.centroid)
            cell.polygon = p
            let wall = Self.make(from: cell)
            wall.physicsBody?.isDynamic = true
//            wall.physicsBody?.density = 0.1
//            wall.fillColor = .yellow
            wall.strokeColor = .red
            return wall
        }
        
        terrain.replace(wall: self, with: walls)
        
        let imp = CGVector(dx: normal.dx * impulse,
                           dy: normal.dy * impulse)
        walls.forEach {
            $0.physicsBody?.applyImpulse(imp, at: contactPoint)
            $0.startMonitoring()
        }
    }
    
    public func destroy() {
        physicsBody = nil
        removeFromParent()
    }
    
    
    private func splitPolygon(_ polygon: Polygon) -> [Polygon] {
//        let vpoints = polygon.map { SitePoint<Void>(point: SIMD2<Double>(x: Double($0.x), y: Double($0.y))) }
        
        
        let minX = polygon.min(by: { $0.x < $1.x })?.x ?? 0
        let minY = polygon.min(by: { $0.y < $1.y })?.y ?? 0
        let maxX = polygon.max(by: { $0.x < $1.x })?.x ?? 0
        let maxY = polygon.max(by: { $0.y < $1.y })?.y ?? 0
        
        
        let clipRect = ClipRect.minMaxXY(minX: Double(minX),
                                         minY: Double(minY),
                                         maxX: Double(maxX),
                                         maxY: Double(maxY))
        
        
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
        
        
        let result = Voronoi.runFortunesAlgorithm(sitePoints: vpoints, clipRect: clipRect, options: [.makeSitePolygonVertices, .makeEdgesOnClipRectBorders], randomlyOffsetSiteLocationsBy: nil)
        let polygons = result.sites.map { site -> Polygon in
            return site.polygonVertices.map { CGPoint(x: $0.x, y: $0.y) }
        }
        
        
        var clippedPolygons = [Polygon]()
        let superPolygon = self.cell?.polygon
        for polygon in polygons {
            guard var intersections  = superPolygon?.intersection(polygon) else { continue }
            intersections = intersections.filter { $0.count >= 3 }
            clippedPolygons.append(contentsOf: intersections)
        }
        
        clippedPolygons = clippedPolygons.map { $0 + [$0[0]] }
        area fix needed:
        clippedPolygons = clippedPolygons.filter { $0.area < -50 }
        
        return clippedPolygons
    }
}
