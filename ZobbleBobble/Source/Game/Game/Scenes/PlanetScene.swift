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
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet")
    private lazy var controlCenterButton: GUIButton = GUIButton(style: .utility, title: "X", tapAction: goToControlCenter)
    private lazy var resultsButton: GUIButton = GUIButton(title: "Game results", tapAction: goToGameResults)
    
    private let levelCenterPoint = CGPoint(x: 0, y: Settings.Camera.levelCenterOffset)
    private var gunCenterPoint: CGPoint { CGPoint(x: 0, y: levelCenterPoint.y + Settings.Camera.starCenterOffset) }
    
    private var planet: PlanetModel
    private var player: PlayerModel
    
    private let physicsWorld: PhysicsWorld
    
    private let terrainBody: TerrainBody?
    private var gun: GunBody
    private var missle: MissleBody?
    
    var isGameOver: Bool = false {
        didSet {
            updateGUI()
        }
    }
    
    override var visibleBodies: [any Body] {
        var result = super.visibleBodies
        
        if let terrainBody = terrainBody { result.append(terrainBody) }
        if let missle = missle { result.append(missle) }
        result.append(gun)
        
        return result
    }
    
    init(currentVisibility: Float = 1, size: CGSize, safeArea: CGRect, screenScale: CGFloat, planet: PlanetModel, player: PlayerModel) {
        self.planet = planet
        self.player = player
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
        
        super.init(currentVisibility: currentVisibility, size: size, safeArea: safeArea, screenScale: screenScale)
        
        self.gui = GUIBody(buttons: [], labels: [titleLabel])
        
        planet.chunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }

        updateGUI()
        spawnNextMissle(animated: true)
    }
    
    override func setupLayout() {
        updateGUI()
        
        let containerIndex = player.selectedContainerIndex ?? 0
        let missleRange = gun.getWorldVisibleMissles(containerIndex: containerIndex, misslesFired: 0)
        
        gun.position = SIMD2<Float>(Float(gunCenterPoint.x), Float(gunCenterPoint.y))
        gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                             containerIndex: CGFloat(containerIndex),
                             visibleMissleRange: missleRange)
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
        controlCenterButton.frame = CGRect(x: safeArea.maxX - hp - squareButtonWidth,
                                           y: safeArea.minY + vp,
                                           width: squareButtonWidth,
                                           height: buttonHeight)
    }
    
    private func updateGUI() {
        guard let gui = gui else { return }
        if isGameOver {
            gui.buttons = [resultsButton]
        } else {
            gui.buttons = [controlCenterButton]
        }
    }
    
    override func update(_ time: CFTimeInterval) {
        physicsWorld.update(time)
    }
    
    override func onTouchUp(pos: CGPoint) {
        super.onTouchUp(pos: pos)
        guard userInteractionEnabled else { return }
        //        guard star.state.currentMissleIndex <= CGFloat(level.missleChunks.count) else {
        ////            game?.runMenu(isFromLevel: true)
        //            return
        //        }
        if gui?.hitTest(pos: pos) != true {
            launchCurrentMissle(to: pos)
            spawnNextMissle()
        }
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
            
            let missleRange = gun.getWorldVisibleMissles(containerIndex: Int(self.gun.state.currentContainerIndex), misslesFired: misslesFired)
            self.gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                                      containerIndex: self.gun.state.currentContainerIndex,
                                      visibleMissleRange: missleRange)
            
            self.missle?.updateMisslePosition(percentage)
        }
        
        let completion = { [weak self] in
            guard let self = self else { return }
            
            let missleRange = gun.getWorldVisibleMissles(containerIndex: Int(self.gun.state.currentContainerIndex), misslesFired: endMissleCount)
            self.gun.updateAppearance(levelToPackProgress: Settings.Camera.levelCameraScale,
                                      containerIndex: self.gun.state.currentContainerIndex,
                                      visibleMissleRange: missleRange)
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
