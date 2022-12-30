//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

final class World: RenderDataSource {
    var world: ZPWorld
    let level: Level
    
    var particleRadius: Float = 2.5
    var liquidCount: Int?
    var liquidPositions: UnsafeMutableRawPointer?
    var liquidVelocities: UnsafeMutableRawPointer?
    var liquidColors: UnsafeMutableRawPointer?
    var circleBodyCount: Int?
    var circleBodiesPositions: UnsafeMutableRawPointer?
    var circleBodiesColors: UnsafeMutableRawPointer?
    var circleBodiesRadii: UnsafeMutableRawPointer?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level) {
        self.level = level
        self.world = ZPWorld(gravity: CGPoint(x: 0, y: 0), particleRadius: CGFloat(particleRadius))
        
        self.world.onHarden = { [weak self] index, color in
            self?.hardenParticle(at: Int(index), color: color)
        }
        
        level.playerShapes.forEach { shape in
            self.spawnCore(at: shape.position, radius: CGFloat(shape.radius), color: shape.color, addToLevel: false)
        }
    }
    
    func update(_ time: CFTimeInterval) {
        autoreleasepool {
            self.world.worldStep(time, velocityIterations: 3, positionIterations: 1)
            
            self.liquidPositions = world.liquidPositions
            self.liquidVelocities = world.liquidVelocities
            self.liquidColors = world.liquidColors
            self.liquidCount = Int(world.liquidCount)
            
            self.circleBodiesPositions = world.circleBodiesPositions
            self.circleBodiesRadii = world.circleBodiesRadii
            self.circleBodiesColors = world.circleBodiesColors
            self.circleBodyCount = Int(world.circleBodyCount)
        }
    }
    
    func spawnCore(at position: CGPoint, radius: CGFloat, color: CGRect, addToLevel: Bool = true) {
        world.addBody(withRadius: Float(radius), position: position, color: color)
        if addToLevel {
            level.addShape(position: position, radius: Float(radius), color: color)
        }
    }
    
    func spawnComet(at position: CGPoint, radius: CGFloat, color: CGRect) {
        let points = Polygon.make(radius: radius, position: position, vertexCount: 6)
        let polygon = points.map { NSValue(cgPoint: $0) }
        let color = Colors.comet.pickColor()
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: false)
    }
    
    func hardenParticle(at index: Int, color: CGRect) {
        let count = Int(2 * world.liquidCount)
        guard (0..<count) ~= index else { return }
        
        let pointer = world.liquidPositions.bindMemory(to: Float32.self, capacity: count)
        let b = UnsafeBufferPointer(start: pointer, count: count)
        let positions = Array(b)
        
        let x = positions[index * 2]
        let y = positions[index * 2 + 1]
        let position = CGPoint(x: CGFloat(x), y: CGFloat(y))
        
        self.spawnCore(at: position, radius: CGFloat(particleRadius), color: color)
        self.world.removeParticle(at: Int32(index))
    }
}
