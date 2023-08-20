//
//  PlanetScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation
import Levels

final class PlanetScene: Scene {
    override var transitionTargetCategory: TransitionTarget { .planet }
    override var background: SIMD4<UInt8> { get { Colors.Background.defaultPack } set { } }
    
    private let levelCenterPoint = CGPoint(x: 0, y: Settings.Camera.levelCenterOffset)
    private var gunCenterPoint: CGPoint { CGPoint(x: 0, y: levelCenterPoint.y + Settings.Camera.gunCenterOffset) }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet")
    private lazy var pauseButton: GUIButton = GUIButton(style: .utility,title: "||", tapAction: onPauseTap)
    private lazy var backToGameButton: GUIButton = GUIButton(style: .utility,title: "Cancel", tapAction: onBackToGameTap)
    private lazy var exitButton: GUIButton = GUIButton(title: "Exit", tapAction: goToControlCenter)
    private lazy var resultsButton: GUIButton = GUIButton(title: "Game results", tapAction: goToGameResults)
    
    private var planet: PlanetModel
    private let physicsWorld: PhysicsWorld
    private let terrainBody: TerrainBody?
    private var gun: GunBody
    private var missle: MissleBody?
    
    var isGameOver: Bool = false { didSet { onStateUpdate() } }
    var isPaused: Bool = true { didSet { onStateUpdate() } }
    
    override var visibleBodies: [any Body] {
        var result = super.visibleBodies
        
        if let terrainBody = terrainBody { result.append(terrainBody) }
        if let missle = missle { result.append(missle) }
        result.append(gun)
        
        return result
    }
    
    override init(game: GameInteractive?, size: CGSize, safeArea: CGRect, screenScale: CGFloat, opacity: Float = 0) {
        guard let player = game?.player else { fatalError() }
        self.planet = player.selectedPlanet
        
        let world = LiquidFunWorld(particleRadius: planet.particleRadius * Settings.Physics.scale,
                                   rotationStep: planet.speed.radians / 60.0,
                                   gravityRadius: planet.gravityRadius,
                                   gravityCenter: levelCenterPoint * Settings.Physics.scale)
        self.physicsWorld = world
        
        let planetMaterials = planet.uniqueMaterials
        let containerMaterials = player.selectedContainer?.uniqueMaterials ?? []
        let uniqueMaterials = Array(Set(planetMaterials + containerMaterials))
        
        self.terrainBody = TerrainBody(physicsWorld: world, uniqueMaterials: uniqueMaterials)
        self.gun = GunBody(player: player)
        
        super.init(game: game, size: size, safeArea: safeArea, screenScale: screenScale, opacity: opacity)
        
        gui = GUIBody(buttons: [], labels: [titleLabel])
        updateGUI()
        
        planet.chunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }
        spawnNextMissle(animated: true)
    }
    
    override func setupLayout() {
        updateGUI()
        
        let missleRange = gun.getWorldVisibleMissles(misslesFired: 0)
        
        gun.position = SIMD2<Float>(Float(gunCenterPoint.x), Float(gunCenterPoint.y))
        gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale, visibleMissleRange: missleRange)
        
        isPaused = false
    }
    
    override func updateLayout() {
        let vp = paddingVertical
        let hp = paddingHorizontal
        
        let buttonWidth = safeArea.width - 2 * hp
        let buttonHeight = buttonHeight
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        
        let labelHeight = titleHeight
        let squareButtonWidth = Constants.buttonHeight * horizontalScale
        
        titleLabel.frame = CGRect(x: safeArea.minX + hp,
                                  y: safeArea.minY + vp,
                                  width: safeArea.width - 2 * hp,
                                  height: labelHeight)
        
        resultsButton.frame = CGRect(x: buttonX,
                                     y: safeArea.maxY - 2 * (buttonHeight + vp),
                                     width: buttonWidth,
                                     height: buttonHeight)
        
        exitButton.frame = CGRect(x: buttonX,
                                  y: safeArea.maxY - 2 * (buttonHeight + vp),
                                  width: buttonWidth,
                                  height: buttonHeight)
        
        backToGameButton.frame = CGRect(x: buttonX,
                                     y: safeArea.maxY - (buttonHeight + vp),
                                     width: buttonWidth,
                                     height: buttonHeight)
        
        pauseButton.frame = CGRect(x: safeArea.maxX - hp - squareButtonWidth,
                                   y: safeArea.minY + vp,
                                   width: squareButtonWidth,
                                   height: buttonHeight)
    }
    
    private func onPauseTap() {
        isPaused = true
    }
    
    private func onBackToGameTap() {
        isPaused = false
    }
    
    private func updateGUI() {
        guard let gui = gui else { return }
        
        switch (isGameOver, isPaused) {
        case (true, _):
            gui.buttons = [resultsButton]
        case (false, true):
            gui.buttons = [backToGameButton, exitButton]
        case (false, false):
            gui.buttons = [pauseButton]
        }
    }
    
    private func onStateUpdate() {
        updateGUI()
    }
    
    override func update(_ time: CFTimeInterval) {
        if !isPaused {
            physicsWorld.update(time)
        }
    }
    
    override func onTouchUp(pos: CGPoint) -> Bool {
        guard userInteractionEnabled, !super.onTouchUp(pos: pos), !isPaused, !isGameOver else { return false }
        
        launchCurrentMissle(to: pos)
        spawnNextMissle()
        return true
    }

    private func spawnChunk(_ chunk: ChunkModel) {
        for i in 0 ..< chunk.particles.count {
            var center = chunk.particles[i].position + levelCenterPoint
            center.x *= Settings.Physics.scale
            center.y *= Settings.Physics.scale
            let material = chunk.particles[i].material

            let flags = material.physicsFlags
            let isStatic = true
            let gravityScale = material.gravityScale
            let freezeVelocityThreshold = material.freezeVelocityThreshold * Settings.Physics.freezeThresholdModifier
            let staticContactBehavior = material.becomesLiquidOnContact
            let color = chunk.particles[i].movementColor

            physicsWorld.addParticle(withPosition: center,
                                     color: color,
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
        guard let selectedMissle = gun.selectedMissle else {
            game?.containerFinished()
            isGameOver = true
            userInteractionEnabled = true
            missle = nil
            gun.missleRadius = 0
            return
        }
        
        self.missle = MissleBody(missleModel: selectedMissle, parent: gun)
        
        let startMissleCount = gun.state.currentMissleIndex
        let endMissleCount = gun.state.currentMissleIndex + 1

        let animation = { [weak self] (percentage: CGFloat) in
            guard let self = self else { return }
            
            let starPercentage = min(1, percentage * Settings.Camera.missleParticleMaxSpeedModifier)
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * starPercentage
            
            let missleRange = gun.getWorldVisibleMissles(misslesFired: misslesFired)
            self.gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale, visibleMissleRange: missleRange)
            
            self.missle?.updateMisslePosition(percentage)
        }
        
        let completion = { [weak self] in
            guard let self = self else { return }
            
            let missleRange = gun.getWorldVisibleMissles(misslesFired: endMissleCount)
            self.gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale, visibleMissleRange: missleRange)
            self.gun.state.currentMissleIndex += 1
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
            let particle = missle.missleModel.particles[i]
            let material = particle.material
            
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

            let color = particle.movementColor

            self?.physicsWorld.addParticle(withPosition: pos,
                                           color: color,
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
