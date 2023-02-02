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
    
    var currentMissleIndex = 0
}

final class World: ObjectRenderDataSource, CameraRenderDataSource {
    weak var game: Game?
    var world: ZPWorld
    var star: Star
    
    let pack: LevelPack
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
    
    var cameraX: Float { Float(state.camera.x + levelCenterPoint.x) }
    var cameraY: Float { Float(state.camera.y + levelCenterPoint.y) }
    var cameraScale: Float { Float(state.cameraScale) }
    var cameraAngle: Float { Float(state.angle) }
    
    private var levelCenterPoint: CGPoint
    private var starCenterPoint: CGPoint
    
    var state: WorldState
    
    var lastQueryStarHadChanges = true
    var starsHasChanges: Bool {
        defer {
            lastQueryStarHadChanges = false
        }
        if lastQueryStarHadChanges {
            return true
        } else {
            return false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(game: Game, star: Star, particleRadius: CGFloat) {
        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
        let level = pack.levels[game.state.levelIndex]
        
        self.pack = pack
        self.level = level
        self.game = game
        self.particleRadius = Float(particleRadius)
        self.levelCenterPoint = game.levelCenterPoint
        
        self.starCenterPoint = CGPoint(x: 0, y: game.screenSize.height * 0.6)
        self.world = ZPWorld(gravityCenter: .zero, gravityRadius: level.targetOutline.radius, particleRadius: CGFloat(particleRadius))
        self.state = WorldState(angle: 0, camera: .zero, cameraScale: 1)
        
        self.star = star
        star.radius = Float(pack.radius)
        star.position = SIMD2<Float>(Float(starCenterPoint.x), Float(starCenterPoint.y))
        star.mainColor = pack.style.mainColor
        star.updateVisibleMaterials(levelToPackProgress: Menu.levelCameraScale)
        
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
        guard state.currentMissleIndex < level.materials.count else {
            // TODO: level finished
//            game?.runMenu(isFromLevel: true)
            return
        }
        let position = screenToGame(position)
        let type = level.materials[state.currentMissleIndex]
        spawnComet(material: type, position: position)
        
//        state.currentMissleIndex += 1
//        star.updateVisibleMaterials(levelToPackProgress: Menu.levelCameraScale, misslesFired: state.currentMissleIndex)
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
    
    private func spawnComet(material: Material, position: CGPoint) {
        switch material {
        case .lavaRed, .lavaYellow:
            spawnLiquidComet(at: position, material: material)
        case .bomb:
            spawnSolidComet(at: position, material: material)
        }
        
        let startMissleCount = CGFloat(state.currentMissleIndex)
        let endMissleCount = CGFloat(state.currentMissleIndex + 1)
        
        Animator.animate(duraion: Settings.shotAnimationDuration, easing: Settings.shotAnimationEasing, step: { percentage in
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * percentage
            self.star.missleIndicesToSkip = misslesFired
            self.star.updateVisibleMaterials(levelToPackProgress: Menu.levelCameraScale)
            self.lastQueryStarHadChanges = true
        }, completion: {
            self.star.missleIndicesToSkip = endMissleCount
            self.star.updateVisibleMaterials(levelToPackProgress: Menu.levelCameraScale)
            self.state.currentMissleIndex += 1
            self.lastQueryStarHadChanges = true
        })
    }
    
    private func spawnLiquidComet(at position: CGPoint, material: Material) {
        let points = Polygon.make(radius: material.missleRadius, position: position, vertexCount: 8)
        let polygon = points.map { NSValue(cgPoint: $0) }
        let color = CGRect(material.color)
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: false, isExplodable: false)
    }
    
    private func spawnSolidComet(at position: CGPoint, material: Material) {
        let points = Polygon.make(radius: material.missleRadius, position: position, vertexCount: 8)
        let polygon = points.map { NSValue(cgPoint: $0) }
        let color = CGRect(material.color)
        world.addLiquid(withPolygon: polygon, color: color, position: .zero, isStatic: false, isExplodable: true)
    }
}

extension World: ObjectPositionProvider {
    var visibleLevelIndices: ClosedRange<Int> {
        game!.state.levelIndex ... game!.state.levelIndex
    }
    
    var visibleLevelPackIndices: ClosedRange<Int> {
        game!.state.packIndex ... game!.state.packIndex
    }
    
    func convertStarPosition(_ index: Int) -> CGPoint? {
        guard let game = game, star.number == index else { return nil }
        let y = game.screenSize.height * 0.6
        return CGPoint(x: 0, y: y)
    }

    func convertStarRadius(_ radius: CGFloat) -> CGFloat? {
        return radius
    }
    
    func convertPlanetPosition(_ index: Int) -> CGPoint? {
        return .zero
    }
    
    func convertPlanetRadius(_ radius: CGFloat) -> CGFloat? {
        radius
    }
}

extension World: StarsRenderDataSource {
    var starPositions: [UnsafeMutableRawPointer] {
        [star.positionPointer]
    }
    
    var starRadii: [UnsafeMutableRawPointer] {
        [star.radiusPointer]
    }
    
    var starMainColors: [UnsafeMutableRawPointer] {
        [star.mainColorPointer]
    }
    
    var starMaterials: [UnsafeMutableRawPointer] {
        [star.materialsPointer]
    }
    
    var starMaterialCounts: [Int] {
        [star.state.visibleMaterials.count]
    }
}
