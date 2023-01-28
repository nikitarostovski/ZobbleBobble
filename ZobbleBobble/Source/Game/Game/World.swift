//
//  World.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import ZobbleCore
import ZobblePhysics

struct WorldState {
    var angle: CGFloat
    var camera: CGPoint
    var cameraScale: CGFloat
}

final class World: RenderDataSource {
    var world: ZPWorld
    let level: Level
    
    var particleRadius: Float
    var liquidFadeModifier: Float = 0.3
    var liquidCount: Int?
    var liquidPositions: UnsafeMutableRawPointer?
    var liquidVelocities: UnsafeMutableRawPointer?
    var liquidColors: UnsafeMutableRawPointer?
    var circleBodyCount: Int?
    var circleBodiesPositions: UnsafeMutableRawPointer?
    var circleBodiesColors: UnsafeMutableRawPointer?
    var circleBodiesRadii: UnsafeMutableRawPointer?
    
    var backgroundAnchorPositions: UnsafeMutableRawPointer? { nil }
    var backgroundAnchorRadii: UnsafeMutableRawPointer? { nil }
    var backgroundAnchorColors: UnsafeMutableRawPointer? { nil }
    var backgroundAnchorPointCount: Int? { nil }
    
    var cameraX: Float { Float(state.camera.x + levelCenterPoint.x) }
    var cameraY: Float { Float(state.camera.y + levelCenterPoint.y) }
    var cameraScale: Float { Float(state.cameraScale) }
    var cameraAngle: Float { Float(state.angle) }
    
    private let levelCenterPoint: CGPoint
    
    var nextCometType: CometType = .liquid
    var state: WorldState
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(level: Level, centerPoint: CGPoint, particleRadius: CGFloat) {
        self.particleRadius = Float(particleRadius)
        self.level = level
        self.levelCenterPoint = centerPoint
        self.world = ZPWorld(gravityCenter: .zero, gravityRadius: level.targetOutline.radius, particleRadius: CGFloat(particleRadius))
        self.state = WorldState(angle: 0, camera: .zero, cameraScale: 1)
        
        level.playerShapes.forEach { shape in
            let position = shape.position//CGPoint(x: levelCenterPoint.x + shape.position.x, y: levelCenterPoint.y + shape.position.y)
            self.spawnCore(at: position, radius: CGFloat(shape.radius), color: shape.color, addToLevel: false)
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
            self.state.angle += CGFloat(time)
        }
    }
    
    func onTap(_ position: CGPoint) {
        let position = screenToGame(position)
        let type = nextCometType
        let color = Colors.comet(type).pickColor()
        spawnComet(type: type, position: position, radius: type.radius, color: color)
    }
    
    func onSwipe(_ offset: CGFloat) {
        
    }
    
    func screenToGame(_ point: CGPoint) -> CGPoint {
        var result = point
        
        var center = CGPoint.zero
        center.x -= state.camera.x + levelCenterPoint.x
        center.y -= state.camera.y + levelCenterPoint.y
        
        let dist = result.distance(to: center)
        let angle = result.angle(to: center) * .pi / 180 + .pi
        
        result.x = cos(angle - state.angle) * dist
        result.y = sin(angle - state.angle) * dist
        
        return CGPoint(x: state.camera.x + result.x / CGFloat(state.cameraScale),
                       y: state.camera.y + result.y / CGFloat(state.cameraScale))
    }
    
    private func spawnCore(at position: CGPoint, radius: CGFloat, color: CGRect, addToLevel: Bool = true) {
        let points = Polygon.make(radius: radius, position: position, vertexCount: 8)
        let polygon = points.map { NSValue(cgPoint: $0) }
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: true, isExplodable: false)
        if addToLevel {
            level.addShape(position: position, radius: Float(radius), color: color)
        }
    }
    
    private func spawnComet(type: CometType, position: CGPoint, radius: CGFloat, color: CGRect) {
        switch type {
        case .liquid:
            spawnLiquidComet(at: position, radius: radius, color: color)
        case .solid:
            spawnSolidComet(at: position, radius: radius, color: color)
        }
    }
    
    private func spawnLiquidComet(at position: CGPoint, radius: CGFloat, color: CGRect) {
        let points = Polygon.make(radius: radius, position: position, vertexCount: 8)
        let polygon = points.map { NSValue(cgPoint: $0) }
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: false, isExplodable: false)
    }
    
    private func spawnSolidComet(at position: CGPoint, radius: CGFloat, color: CGRect) {
        let points = Polygon.make(radius: radius, position: position, vertexCount: 8)
        let polygon = points.map { NSValue(cgPoint: $0) }
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: false, isExplodable: true)
    }
}
