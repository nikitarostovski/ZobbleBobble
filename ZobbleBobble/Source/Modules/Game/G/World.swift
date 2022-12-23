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
    
    var polygonMesh: PolygonMesh
    var circleMesh: CircleMesh
    var liquidMesh: LiquidMesh
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level) {
        self.world = ZPWorld(gravity: CGPoint(x: 0, y: 0), particleRadius: particleRadius)
        self.polygonMesh = PolygonMesh()
        self.circleMesh = CircleMesh()
        self.liquidMesh = LiquidMesh()
        
        self.world.onHarden = { [weak self] index in
            self?.hardenParticle(at: Int(index))
        }
    }
    
    func update(_ time: CFTimeInterval) {
        autoreleasepool {
            self.world.worldStep(time, velocityIterations: 6, positionIterations: 2)
            
//            let positions = UnsafeMutableRawPointer(
//            let float4Ptr = ptr.bindMemory(to: float4.self, capacity: length)
//            let float4Buffer = UnsafeBufferPointer(start: float4Ptr, count: length)
//            let circles = world.bodies.compactMap { (body) -> RenderData? in
//                guard let body = body as? ZPBody else { return nil }
//                return .circle(position: body.position, radius: CGFloat(body.radius), color: SIMD4<UInt8>(1, 0, 0, 1))
//            }
            
            self.liquidMesh.updateMeshIfNeeded(vertexCount: Int(world.liquidCount), vertices: world.liquidPositions, colors: world.liquidColors)
            
            self.circleMesh.updateMeshIfNeeded(positions: world.circleBodiesPositions, radii: world.circleBodiesRadii, colors: world.circleBodiesColors, count: Int(world.circleBodyCount))
//            self.circleMesh.updateMeshIfNeeded(positions: <#T##UnsafeMutableRawPointer#>, count: <#T##Int#>, radius: <#T##Float#>, color: <#T##SIMD4<UInt8>#>, device: <#T##MTLDevice#>)
            
    //        let positionsPointer = world.liquidPositions.bindMemory(to: SIMD2<Float>.self, capacity: Int(world.liquidCount))
    //        let positions = UnsafeBufferPointer(start: positionsPointer, count: Int(world.liquidCount))
    //
    //        let colorsPointer = world.liquidPositions.bindMemory(to: SIMD4<UInt8>.self, capacity: Int(world.liquidCount))
    //        let colors = UnsafeBufferPointer(start: colorsPointer, count: Int(world.liquidCount))
            
//            let liquids = [RenderData.liquid(count: Int(world.liquidCount), radius: particleRadius, positions: world.liquidPositions, colors: world.liquidColors)]
//            case .polygon(let polygon, let color):
//                (mesh as? PolygonMesh)?.updateMeshIfNeeded(vertices: polygon.map { SIMD2<Float>(Float($0.x), Float($0.y)) }, color: color, device: device)
//            case .circle(let position, let radius, let color):
//                (mesh as? CircleMesh)?.updateMeshIfNeeded(position: SIMD2<Float>(Float(position.x), Float(position.y)), radius: Float(radius), color: color, device: device)
//            case .liquid(let count, let radius, let positions, let colors):
//                (mesh as? LiquidMesh)?.updateMeshIfNeeded(vertexCount: count, vertices: positions, colors: colors, radius: Float(radius), device: device)
//            }
        }
    }
    
    func spawnCore(at position: CGPoint) {
        let radius: CGFloat = 20
//        let points = Polygon.make(radius: radius, position: position, vertexCount: 5)
//        let polygon = points.map { NSValue(cgPoint: $0) }
//        world.addBody(withPolygon: polygon, position: .zero)
        world.addBody(withRadius: Float(radius), position: position)
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
//        let vertexCount = 6
//
//        var polygon = Polygon()
//        for i in 0 ..< vertexCount {
//            let a: CGFloat = 2 * .pi * CGFloat(i) / CGFloat(vertexCount)
//            let v = CGPoint(x: position.x + radius * cos(a), y: position.y + radius * sin(a))
//            polygon.append(v)
//        }
        
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
        
//        let allPolygons: [Polygon] = world.bodies.compactMap { ($0 as? ZPBody)?.polygon.map { $0.cgPointValue } }
//        let finalPolygons = [polygon]
        
//        print("!!! \(allPolygons.count) -> \(finalPolygons.count)")
        
//            for i in 0 ..< self.world.bodies.count {
//                self.world.removeBody(at: Int32(i))
//            }
            
//            for p in finalPolygons {
//                let polygon = p.map { NSValue(cgPoint: $0) }
//                self.world.addBody(withPolygon: polygon, position: .zero)
//            }
        
        self.world.addBody(withRadius: Float(radius), position: position)
        self.world.removeParticle(at: Int32(index))
    }
}
