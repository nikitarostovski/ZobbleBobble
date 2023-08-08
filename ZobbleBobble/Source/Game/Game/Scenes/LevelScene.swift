//
//  LevelScene.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit
import Levels

final class LevelScene {
    private var starCenterPoint: CGPoint { game.map { CGPoint(x: 0, y: $0.levelCenterPoint.y + Settings.Camera.starCenterOffset) } ?? .zero }
    
    private let pack: PackModel
    private let level: LevelModel
    private weak var game: Game?
    private let physicsWorld: PhysicsWorld
    
    private let star: StarBody
    private var missle: MissleBody? {
        didSet {
            game?.replace(missles: [missle].compactMap { $0 })
        }
    }
    
    private var userInteractionEnabled = true
    
    private var lastQueryStarHadChanges = true
    private var starsHasChanges: Bool {
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
    
    init(game: Game) {
        let pack = game.currentPack!
        let level = game.currentLevel!
        
        let world = LiquidFunWorld(particleRadius: pack.particleRadius * Settings.Physics.scale,
                                   rotationStep: level.rotationPerSecond.radians / 60.0,
                                   gravityRadius: level.gravityRadius,
                                   gravityCenter: game.levelCenterPoint * Settings.Physics.scale)
        
        let starBody = game.stars.first(where: { $0.pack == pack })!
        
        let terrainBody = TerrainBody(physicsWorld: world, uniqueMaterials: Array(Set(level.allMaterials)))
        game.replace(stars: [starBody], terrains: [terrainBody], missles: [])
        
        self.pack = pack
        self.level = level
        self.game = game
        self.star = starBody
        self.physicsWorld = world

        star.radius = Float(pack.radius)
        star.position = SIMD2<Float>(Float(starCenterPoint.x), Float(starCenterPoint.y))
        let missleRange = star.getWorldVisibleMissles(levelIndex: game.state.levelIndex, misslesFired: 0)
        star.updateStarAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                                  levelIndex: CGFloat(game.state.levelIndex),
                                  visibleMissleRange: missleRange)
        
        level.initialChunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }
        
        spawnNextMissle(animated: true)
    }
    
    func update(_ time: CFTimeInterval) {
        physicsWorld.update(time)
    }
    
    func onTap(_ position: CGPoint) {
        guard userInteractionEnabled else { return }
        
        guard star.state.currentMissleIndex <= CGFloat(level.missleChunks.count) else {
            // TODO: level finished
//            game?.runMenu(isFromLevel: true)
            return
        }
        
        launchCurrentMissle(to: position)
        spawnNextMissle()
    }
    
    func onSwipe(_ offset: CGFloat) { }
    
    private func spawnChunk(_ chunk: ChunkModel) {
        for i in 0 ..< chunk.particles.count {
            var center = chunk.particles[i].position + (game?.levelCenterPoint ?? .zero)
            center.x *= Settings.Physics.scale
            center.y *= Settings.Physics.scale
            let material = chunk.particles[i].material
            
            let flags = material.physicsFlags
            let isStatic = true
            let gravityScale = material.gravityScale
            let freezeVelocityThreshold = material.freezeVelocityThreshold * Settings.Physics.freezeThresholdModifier
            let staticContactBehavior = material.becomesLiquidOnContact
            
            physicsWorld.addParticle(withPosition: center,
                                     color: material.color,
                                     flags: flags,
                                     isStatic: isStatic,
                                     gravityScale: gravityScale,
                                     freezeVelocityThreshold: freezeVelocityThreshold,
                                     becomesLiquidOnContact: staticContactBehavior,
                                     explosionRadius: material.explosionRadius,
                                     shootImpulse: 0)
        }
    }
    
    private func spawnNextMissle(animated: Bool = true) {
        guard star.state.currentMissleIndex < CGFloat(level.missleChunks.count) else {
            self.missle = nil
            self.star.missleRadius = 0
            return
        }
        
        let currentLevel = CGFloat(game?.state.levelIndex ?? 0)
        
        let missleModel = level.missleChunks[Int(star.state.currentMissleIndex)]
        self.missle = MissleBody(missleModel: missleModel, star: star, game: game)
        
        let startMissleCount = star.state.currentMissleIndex
        let endMissleCount = star.state.currentMissleIndex + 1
        
        let animation = { (percentage: CGFloat) in
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * percentage
            
            let missleRange = self.star.getWorldVisibleMissles(levelIndex: Int(currentLevel), misslesFired: misslesFired)
            self.star.updateStarAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                                           levelIndex: currentLevel,
                                           visibleMissleRange: missleRange)
            self.lastQueryStarHadChanges = true
            
            self.missle?.updateMisslePosition(percentage)
        }
        
        let completion = {
            let missleRange = self.star.getWorldVisibleMissles(levelIndex: Int(currentLevel), misslesFired: endMissleCount)
            self.star.updateStarAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                                           levelIndex: currentLevel,
                                           visibleMissleRange: missleRange)
            self.star.state.currentMissleIndex += 1
            self.lastQueryStarHadChanges = true
            self.userInteractionEnabled = true
            
            self.missle?.updateMisslePosition(1)
        }
        
        if animated {
            Animator.animate(duraion: Settings.Camera.shotAnimationDuration, easing: Settings.Camera.shotAnimationEasing, step: animation, completion: completion)
        } else {
            completion()
        }
    }
    
    private func launchCurrentMissle(to position: CGPoint) {
        guard let missle = missle else { return }
        
        userInteractionEnabled = false
        
        missle.positions.enumerated().forEach { [weak self] i, center in
            let material = missle.missleModel.particles[i].material
            
            let flags = material.physicsFlags
            let isStatic = false
            let gravityScale = material.gravityScale
            let freezeVelocityThreshold = material.freezeVelocityThreshold * Settings.Physics.freezeThresholdModifier
            let staticContactBehavior = material.becomesLiquidOnContact
            
            var pos = CGPoint(x: CGFloat(center.x) * Settings.Physics.scale,
                              y: CGFloat(center.y) * Settings.Physics.scale)
            
            let dist = pos.distance(to: .zero)
            let angle = pos.angle(to: .zero) * .pi / 180 + .pi
            
            pos.x = dist * cos(angle)
            pos.y = dist * sin(angle)
            
            self?.physicsWorld.addParticle(withPosition: pos,
                                           color: material.color,
                                           flags: flags,
                                           isStatic: isStatic,
                                           gravityScale: gravityScale,
                                           freezeVelocityThreshold: freezeVelocityThreshold,
                                           becomesLiquidOnContact: staticContactBehavior,
                                           explosionRadius: material.explosionRadius,
                                           shootImpulse: missle.missleModel.startImpulse)
        }
    }
}
