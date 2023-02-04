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
    
    let pack: PackModel
    let level: LevelModel
    
    var particleRadius: Float { Float(level.particleRadius) }
    
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
    
    var userInteractionEnabled = true
    
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
    
    init(game: Game, star: Star) {
        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
        let level = pack.levels[game.state.levelIndex]
        
        self.pack = pack
        self.level = level
        self.game = game
        self.levelCenterPoint = game.levelCenterPoint
        
        self.starCenterPoint = CGPoint(x: 0, y: game.screenSize.height * 0.6)
        self.world = ZPWorld(gravityCenter: .zero, gravityRadius: level.gravityRadius, particleRadius: level.particleRadius)
        self.state = WorldState(angle: 0, camera: .zero, cameraScale: 1)
        
        self.star = star
        star.radius = Float(pack.radius)
        star.position = SIMD2<Float>(Float(starCenterPoint.x), Float(starCenterPoint.y))
        star.updateVisibleMissles(levelToPackProgress: Menu.levelCameraScale)
        
        level.initialChunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }
        
//        level.playerShapes.forEach { shape in
//            let position = shape.position//CGPoint(x: levelCenterPoint.x + shape.position.x, y: levelCenterPoint.y + shape.position.y)
//            self.spawnCore(at: position, radius: CGFloat(shape.radius), color: shape.color, addToLevel: false)
//        }
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
        guard userInteractionEnabled else { return }
        
        guard state.currentMissleIndex < level.missles.count else {
            // TODO: level finished
//            game?.runMenu(isFromLevel: true)
            return
        }
        let position = screenToGame(position)
        spawnMissle(level.missles[state.currentMissleIndex], at: position)
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
    
    private func spawnChunk(_ chunk: ChunkModel) {
        let particleCenters = chunk.shape.particleCenters
        particleCenters.forEach { [weak self] center in
            self?.world.addParticle(withPosition: center,
                                    color: CGRect(chunk.material.color),
                                    isStatic: true,
                                    isExplodable: false)
        }
    }
    
    private func spawnMissle(_ missle: MissleModel, at position: CGPoint) {
        userInteractionEnabled = false
        
        let isExplodable = missle.material == .bomb
        let particleCenters = missle.shape.particleCenters
        
        particleCenters.forEach { [weak self] center in
            let pos = CGPoint(x: position.x + center.x, y: position.y + center.y)
            self?.world.addParticle(withPosition: pos,
                                    color: CGRect(missle.material.color),
                                    isStatic: false,
                                    isExplodable: isExplodable)
        }
        
        let startMissleCount = CGFloat(state.currentMissleIndex)
        let endMissleCount = CGFloat(state.currentMissleIndex + 1)
        
        Animator.animate(duraion: Settings.shotAnimationDuration, easing: Settings.shotAnimationEasing, step: { percentage in
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * percentage
            self.star.missleIndicesToSkip = misslesFired
            self.star.updateVisibleMissles(levelToPackProgress: Menu.levelCameraScale)
            self.lastQueryStarHadChanges = true
        }, completion: {
            self.star.missleIndicesToSkip = endMissleCount
            self.star.updateVisibleMissles(levelToPackProgress: Menu.levelCameraScale)
            self.state.currentMissleIndex += 1
            self.lastQueryStarHadChanges = true
            self.userInteractionEnabled = true
        })
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
