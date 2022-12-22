//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

final class World {
    let particleRadius: CGFloat = 2
    var world: ZPWorld
    
    private var cachedPolygonCount = 0
    private var polygonCached: [PolygonRenderData] = []
    
    var polygonRenderData: [PolygonRenderData] {
        if world.bodies.count != cachedPolygonCount {
            polygonCached = world.bodies.compactMap { body in
                guard let body = body as? ZPBody else { return nil }
                let polygon = body.polygon.map { $0.cgPointValue }
                return PolygonRenderData(polygon: polygon)
            }
            cachedPolygonCount = world.bodies.count
        }
        return polygonCached
    }
    
    var liquidRenderData: [LiquidRenderData] {
        var result = [LiquidRenderData]()
        var points = [CGPoint]()
        
        let pointer = world.liquidPositions.bindMemory(to: Float32.self, capacity: Int(2 * world.liquidCount))
        let b = UnsafeBufferPointer(start: pointer, count: Int(2 * world.liquidCount))
        
        var x: Float32 = 0
        for (i, value) in b.enumerated() {
            if i % 2 == 0 {
                x = value
            } else {
                points.append(CGPoint(x: CGFloat(x), y: CGFloat(value)))
            }
        }
        
        result.append(LiquidRenderData(positions: points))
        return result
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level) {
        self.world = ZPWorld(gravity: CGPoint(x: 0, y: 0), particleRadius: particleRadius)
        self.world.onHarden = { [weak self] index in
            self?.hardenParticle(at: Int(index))
        }
    }
    
    func update(_ time: CFTimeInterval) {
        autoreleasepool {
            self.world.worldStep(time, velocityIterations: 6, positionIterations: 2)
        }
    }
    
    func spawnCore(at position: CGPoint) {
        let radius: CGFloat = 20
        let points = Polygon.make(radius: radius, position: position, vertexCount: 5)
        let polygon = points.map { NSValue(cgPoint: $0) }
        world.addBody(withPolygon: polygon, position: .zero)
//        world.addLiquid(withPolygon: polygon, position: .zero, isStatic: true)
    }
    
    func spawnComet(at position: CGPoint) {
        let radius = CGFloat.random(in: 10...20)
        let points = Polygon.make(radius: radius, position: position, vertexCount: 6)
        let polygon = points.map { NSValue(cgPoint: $0) }
        
        world.addLiquid(withPolygon: polygon, position: .zero, isStatic: false)
    }
    
    func hardenParticle(at index: Int) {
        let count = Int(2 * world.liquidCount)
        guard (0..<count) ~= index else { return }
        
        let pointer = world.liquidPositions.bindMemory(to: Float32.self, capacity: count)
        let b = UnsafeBufferPointer(start: pointer, count: count)
        let positions = Array(b)
        
        let x = positions[index * 2]
        let y = positions[index * 2 + 1]
        let position = CGPoint(x: CGFloat(x), y: CGFloat(y))
        
        let radius = particleRadius
        let vertexCount = 6
        
        var polygon = Polygon()
        for i in 0 ..< vertexCount {
            let a: CGFloat = 2 * .pi * CGFloat(i) / CGFloat(vertexCount)
            let v = CGPoint(x: position.x + radius * cos(a), y: position.y + radius * sin(a))
            polygon.append(v)
        }
        
//        let a = position.angle(to: .zero) * .pi / 180
//        let coreRadius: CGFloat = 50
//
//        let particleA = CGPoint(x: position.x + radius * cos(a - .pi / 2), y: position.y + radius * sin(a - .pi / 2))
//        let particleB = CGPoint(x: position.x + radius * cos(a + .pi / 2), y: position.y + radius * sin(a + .pi / 2))
//        let coreA = CGPoint(x: coreRadius * cos(a - .pi / 2), y: coreRadius * sin(a - .pi / 2))
//        let coreB = CGPoint(x: coreRadius * cos(a + .pi / 2), y: coreRadius * sin(a + .pi / 2))
//
//        let extraPolygon: Polygon = [particleA, particleB, coreB, coreA]
//        var newPolygons = [polygon] + extraPolygon.difference(from: polygon)
////        let newPolygon = newPolygons.convexHull()
//
//        let allPolygons: [Polygon] = world.bodies.compactMap { ($0 as? ZPBody)?.polygon.map { $0.cgPointValue } }
//
//        var result = newPolygons//[newPolygon]
//
//        for op in allPolygons {
//            var newResult = [Polygon]()
//            for r in result {
//                let diff = r.difference(from: op)
//                newResult.append(contentsOf: diff)
//            }
//            result = newResult
//        }
//        newPolygons = result//.map { $0.triangulate() }.flatMap { $0 }
//        var finalPolygons = newPolygons + allPolygons
//
//        finalPolygons = finalPolygons.unions().map { $0.triangulate() }.flatMap { $0 }
//
//        finalPolygons = finalPolygons.map { $0.removeDuplicates() }.filter { $0.count > 2 }
        
        let allPolygons: [Polygon] = world.bodies.compactMap { ($0 as? ZPBody)?.polygon.map { $0.cgPointValue } }
        let finalPolygons = [polygon]
        
//        print("!!! \(allPolygons.count) -> \(finalPolygons.count)")
        
//            for i in 0 ..< self.world.bodies.count {
//                self.world.removeBody(at: Int32(i))
//            }
            
            for p in finalPolygons {
                let polygon = p.map { NSValue(cgPoint: $0) }
                self.world.addBody(withPolygon: polygon, position: .zero)
            }
            
            self.world.removeParticle(at: Int32(index))
    }
}


