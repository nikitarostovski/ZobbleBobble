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

final class World: ObjectRenderDataSource, CameraRenderDataSource {
    weak var game: Game?
    var world: ZPWorld
    var star: Star
    var missle: Missle?
    
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
    
    var staticLiquidCount: Int?
    var staticLiquidPositions: UnsafeMutableRawPointer?
    var staticLiquidVelocities: UnsafeMutableRawPointer?
    var staticLiquidColors: UnsafeMutableRawPointer?
    
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
        
        let def = ZPWorldDef()
        def.center = .zero
        def.gravityRadius = level.gravityRadius
        def.radius = Float(level.particleRadius)
        
//        def.dampingStrength = 0
//        def.gravityScale = 1
//        def.density = 1
        def.viscousStrength = 0.9
        def.repulsiveStrength = 0.2
        def.ejectionStrength = 0
        def.powderStrength = 0.0
        
        def.surfaceTensionNormalStrength = 0
        def.surfaceTensionPressureStrength = 0.2
        def.viscousStrength = 1.0
        def.elasticStrength = 0.1
        
//        def.staticPressureStrength = 0.2
//        def.staticPressureRelaxation = 0.2
//        def.staticPressureIterations = 1//8

        
        
        
        self.world = ZPWorld(worldDef: def)
        self.state = WorldState(angle: 0, camera: .zero, cameraScale: 1)
        
        self.star = star

        star.radius = Float(pack.radius)
        star.position = SIMD2<Float>(Float(starCenterPoint.x), Float(starCenterPoint.y))
        let missleRange = star.getWorldVisibleMissles(levelIndex: game.state.levelIndex, misslesFired: 0)
        star.updateStarAppearance(levelToPackProgress: Settings.levelCameraScale,
                                  levelIndex: CGFloat(game.state.levelIndex),
                                  visibleMissleRange: missleRange)
        
        level.initialChunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }
        
        spawnNextMissle(animated: true)
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
            
            self.staticLiquidPositions = missle?.staticLiquidPositions
            self.staticLiquidColors = missle?.staticLiquidColors
            self.staticLiquidVelocities = missle?.staticLiquidVelocities
            self.staticLiquidCount = missle?.staticLiquidCount
            
            self.state.angle += CGFloat(time) * level.rotationPerSecond / 60.0
        }
    }
    
    func onTap(_ position: CGPoint) {
        guard userInteractionEnabled else { return }
        
        guard star.state.currentMissleIndex <= CGFloat(level.missles.count) else {
            // TODO: level finished
//            game?.runMenu(isFromLevel: true)
            return
        }
        
        launchCurrentMissle(to: position)
        spawnNextMissle()
    }
    
    func onSwipe(_ offset: CGFloat) {
        
    }
    
    func gameToScreen(_ point: CGPoint) -> CGPoint {
        var result = point
        result.x *= state.cameraScale
        result.x -= state.camera.x
        result.y *= state.cameraScale
        result.y -= state.camera.y

        let dist = result.distance(to: .zero)
        let angle = result.angle(to: .zero) * .pi / 180 + .pi

        result.x = cos(angle - state.angle) * dist * state.cameraScale
        result.y = sin(angle - state.angle) * dist * state.cameraScale

        return CGPoint(x: result.x - state.camera.x,
                       y: result.y - state.camera.y)
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
        
        let flags = chunk.material.physicsFlags
        let isStatic = true
        let gravityScale = chunk.material.gravityScale
        let freezeVelocityThreshold = chunk.material.freezeVelocityThreshold
        let staticContactBehavior = chunk.material.becomesLiquidOnContact
        
        particleCenters.forEach { [weak self] center in
            self?.world.addParticle(withPosition: center,
                                    color: CGRect(chunk.material.color),
                                    flags: flags,
                                    isStatic: isStatic,
                                    gravityScale: gravityScale,
                                    freezeVelocityThreshold: freezeVelocityThreshold,
                                    becomesLiquidOnContact: staticContactBehavior,
                                    explosionRadius: chunk.material.explosionRadius,
                                    shootImpulse: 0)
        }
    }
    
    private func spawnNextMissle(animated: Bool = true) {
        guard star.state.currentMissleIndex < CGFloat(level.missles.count) else {
            self.missle = nil
            self.star.missleRadius = 0
            return
        }
        
        let currentLevel = CGFloat(game?.state.levelIndex ?? 0)
        
        let missleModel = level.missles[Int(star.state.currentMissleIndex)]
        self.missle = Missle(missleModel: missleModel, star: star, game: game)
        
        let startMissleCount = star.state.currentMissleIndex
        let endMissleCount = star.state.currentMissleIndex + 1
        
        let animation = { (percentage: CGFloat) in
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * percentage
            
            let missleRange = self.star.getWorldVisibleMissles(levelIndex: Int(currentLevel), misslesFired: misslesFired)
            self.star.updateStarAppearance(levelToPackProgress: Settings.levelCameraScale,
                                           levelIndex: currentLevel,
                                           visibleMissleRange: missleRange)
            self.lastQueryStarHadChanges = true
            
            self.missle?.updateMisslePosition(percentage)
        }
        
        let completion = {
            let missleRange = self.star.getWorldVisibleMissles(levelIndex: Int(currentLevel), misslesFired: endMissleCount)
            self.star.updateStarAppearance(levelToPackProgress: Settings.levelCameraScale,
                                           levelIndex: currentLevel,
                                           visibleMissleRange: missleRange)
            self.star.state.currentMissleIndex += 1
            self.lastQueryStarHadChanges = true
            self.userInteractionEnabled = true
            
            self.missle?.updateMisslePosition(1)
        }
        
        if animated {
            Animator.animate(duraion: Settings.shotAnimationDuration, easing: Settings.shotAnimationEasing, step: animation, completion: completion)
        } else {
            completion()
        }
    }
    
    private func launchCurrentMissle(to position: CGPoint) {
        guard let missle = missle else { return }
        
        userInteractionEnabled = false
        
        let flags = missle.missleModel.material.physicsFlags
        let isStatic = false
        let gravityScale = missle.missleModel.material.gravityScale
        let freezeVelocityThreshold = missle.missleModel.material.freezeVelocityThreshold
        let staticContactBehavior = missle.missleModel.material.becomesLiquidOnContact
        
        missle.positions.forEach { [weak self] center in
            var pos = CGPoint(x: CGFloat(center.x), y: CGFloat(center.y))
            let dist = pos.distance(to: .zero)
            let angle = pos.angle(to: .zero) * .pi / 180 + .pi
            
            pos.x = dist * cos(angle - state.angle)
            pos.y = dist * sin(angle - state.angle)
            
            self?.world.addParticle(withPosition: pos,
                                    color: CGRect(missle.missleModel.material.color),
                                    flags: flags,
                                    isStatic: isStatic,
                                    gravityScale: gravityScale,
                                    freezeVelocityThreshold: freezeVelocityThreshold,
                                    becomesLiquidOnContact: staticContactBehavior,
                                    explosionRadius: missle.missleModel.material.explosionRadius,
                                    shootImpulse: missle.missleModel.startImpulse)
        }
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
    
    var starRenderCenters: [UnsafeMutableRawPointer] {
        [star.renderCenterPointer]
    }
    
    var starMissleCenters: [UnsafeMutableRawPointer] {
        [star.missleCenterPointer]
    }
    
    var starRadii: [UnsafeMutableRawPointer] {
        [star.radiusPointer]
    }
    
    var starMissleRadii: [UnsafeMutableRawPointer] {
        [star.missleRadiusPointer]
    }
    
    var starMaterials: [UnsafeMutableRawPointer] {
        [star.materialsPointer]
    }
    
    var starMaterialCounts: [Int] {
        [star.state.visibleMaterials.count]
    }
    
    var starTransitionProgress: Float {
        Float(Settings.levelsMenuCameraScale)
    }
}
