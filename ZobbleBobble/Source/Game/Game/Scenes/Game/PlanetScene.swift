//
//  PlanetScene.swift
//  ZobbleBobble
//
//  Created by Rost on 16.08.2023.
//

import Foundation

final class PlanetScene: Scene {
    enum GameState {
        case normal
        case paused
        case gameOver
    }
    
    override var transitionTargetCategory: TransitionTarget { .planet }
    override var background: SIMD4<UInt8> { get { Colors.Background.defaultPack } set { } }
    
    private let levelCenterPoint = CGPoint(x: 0, y: Settings.Camera.levelCenterOffset)
    private var gunCenterPoint: CGPoint { CGPoint(x: 0, y: levelCenterPoint.y + Settings.Camera.gunCenterOffset) }
    
    private var gameState: GameState { didSet { onStateUpdate() } }
    
    private lazy var titleLabel: GUILabel = GUILabel(text: "Planet") { [weak self] _ in
        guard let self = self else { return .zero }
        let t = CGRect(x: safeArea.minX + paddingHorizontal,
                      y: safeArea.minY + paddingVertical,
                      width: safeArea.width - 2 * paddingHorizontal,
                      height: titleHeight)
        return t
        
    }
    private lazy var pauseButton: GUIButton = GUIButton(style: .utility, title: "||", tapAction: onPauseTap) { [weak self] _ in
        guard let self = self else { return .zero }
        let squareButtonWidth = Constants.buttonHeight * horizontalScale
        return CGRect(x: safeArea.maxX - paddingHorizontal - squareButtonWidth,
                      y: safeArea.minY + paddingVertical,
                      width: squareButtonWidth,
                      height: buttonHeight)
    }
    private lazy var backToGameButton: GUIButton = GUIButton(style: .utility, title: "Cancel", tapAction: onBackToGameTap) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    private lazy var exitButton: GUIButton = GUIButton(title: "Exit", tapAction: goToControlCenter) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 2 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    private lazy var resultsButton: GUIButton = GUIButton(title: "Game results", tapAction: goToGameResults) { [weak self] _ in
        guard let self = self else { return .zero }
        let buttonWidth = safeArea.width - 2 * paddingHorizontal
        let buttonX = safeArea.minX + (safeArea.width - buttonWidth) / 2
        return CGRect(x: buttonX,
                      y: safeArea.maxY - 2 * (buttonHeight + paddingVertical),
                      width: buttonWidth,
                      height: buttonHeight)
    }
    
    private let physicsWorld: LiquidFunWorld
    private let terrain: TerrainBody?
    private var gun: GunBody
    private var container: ContainerBody
    private var missle: MissleBody?
    
    private var animation: TimerAnimation?
    
    private let worldWidth: Int
    private let worldHeight: Int
    
    override var visibleBodies: [any Body] {
        let result: [(any Body)?] = [gui, terrain]//[gui, gun, terrain, missle, container]
        return result.compactMap { $0 }
    }
    
    override init(game: Game?, size: CGSize, safeArea: CGRect, screenScale: CGFloat, opacity: Float = 0) {
        guard let player = game?.player, let planet = player.selectedPlanet, let container = player.selectedContainer else { fatalError() }
        
        let height = Int(Settings.Camera.sceneHeight)
        let width = Int(size.width * CGFloat(height) / size.height)
        let world = LiquidFunWorld(width: width,
                                   height: height,
                                   rotationStep: planet.speed.radians / 60.0,
                                   gravityRadius: planet.gravityRadius,
                                   gravityCenter: levelCenterPoint * Settings.Physics.scale)
        self.physicsWorld = world
        
        self.worldWidth = width
        self.worldHeight = height
        
        let containerBody = ContainerBody(container: container, frame: .zero)
        self.container = containerBody
        self.terrain = TerrainBody(physicsWorld: world)
        self.gun = GunBody(player: player, container: containerBody, frame: .zero)
        self.gameState = .normal
        
        super.init(game: game, size: size, safeArea: safeArea, screenScale: screenScale, opacity: opacity)
        
        planet.chunks.forEach { [weak self] chunk in
            self?.spawnChunk(chunk)
        }
        spawnNextMissle(animated: true)
    }
    
    override func setupLayout() {
        super.setupLayout()
        
        gun.size = .init(width: Settings.Camera.gunRadius, height: 2 * Settings.Camera.gunRadius)
        gun.center = gunCenterPoint
        
        let height: CGFloat = gun.size.height * 0.7
        let width = height / ContainerBody.aspectRatio
        
        container.size = .init(width: width, height: height)
        container.center = gun.center
        container.origin.y = gun.origin.y
        
        updateGUI()
    }
    
    private func onPauseTap() {
        gameState = .paused
    }
    
    private func onBackToGameTap() {
        gameState = .normal
    }
    
    private func updateGUI() {
        titleLabel.text = game?.player.selectedPlanet?.name
        var visible: [GUIView] = [titleLabel]
        
        switch gameState {
        case .normal:
            visible.append(pauseButton)
        case .gameOver:
            visible.append(resultsButton)
        case .paused:
            visible.append(backToGameButton)
            visible.append(exitButton)
        }
        if let gui = gui {
            gui.views = visible
        } else {
            self.gui = GUIBody(views: visible)
        }
    }
    
    private func onStateUpdate() {
        updateGUI()
        updateLayout()
    }
    
    override func update(_ time: CFTimeInterval) {
        if gameState != .paused  {
            physicsWorld.step(time)
        }
    }
    
    override func onTouchUp(pos: CGPoint) -> Bool {
        guard userInteractionEnabled, !super.onTouchUp(pos: pos), gameState == .normal else { return false }
        
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
            if let game = game {
                if let index = game.player.selectedContainerIndex {
                    game.removeContainer(index)
                }
                if !game.selectContainer(0) {
                    game.clearSelectedContainer()
                }
            }
            gameState = .gameOver
            userInteractionEnabled = true
            missle = nil
            return
        }

        self.missle = MissleBody(missleModel: selectedMissle, parent: gun)

        let startMissleCount = gun.currentMissleIndex
        let endMissleCount = gun.currentMissleIndex + 1

        let animations = { [weak self] (progress: Double, _: TimeInterval) in
            guard let self = self else { return }

            let starPercentage = min(1, progress * Settings.Camera.missleParticleMaxSpeedModifier)
            let misslesFired = startMissleCount + (endMissleCount - startMissleCount) * starPercentage

            gun.currentMissleIndex = misslesFired
            missle?.updateMisslePosition(progress)
        }

        let completion = { [weak self] (_ : Bool) in
            guard let self = self else { return }

            self.animation?.invalidate()
            self.animation = nil
            self.gun.currentMissleIndex = endMissleCount
            self.userInteractionEnabled = true

            self.missle?.updateMisslePosition(1)
        }

        if animated {
            animation = TimerAnimation(duration: Settings.Camera.shotAnimationDuration, animations: animations, completion: completion)
        } else {
            completion(true)
        }
    }

    private func launchCurrentMissle(to position: CGPoint) {
        guard let missle = missle else { return }

        userInteractionEnabled = false

//        missle.positions.enumerated().forEach { [weak self] i, center in
//            let particle = missle.missleModel.particles[i]
//            let material = particle.material
//
//            let flags = material.physicsFlags
//            let isStatic = false
//            let gravityScale = material.gravityScale
//            let freezeVelocityThreshold = material.freezeVelocityThreshold * Settings.Physics.freezeThresholdModifier
//            let staticContactBehavior = material.becomesLiquidOnContact
//
//            var pos = CGPoint(x: CGFloat(center.x),
//                              y: CGFloat(center.y))
//
//            let dist = pos.distance(to: .zero)
//            let angle = pos.angle(to: .zero) * .pi / 180 + .pi
//
//            pos.x = dist * cos(angle)
//            pos.y = dist * sin(angle)
//
//            let color = particle.movementColor
//
//            let x = Int(pos.x)
//            let y = Int(pos.y)
//            let e = Sand(x: x, y: y)
//            self?.physicsWorld.add(element: e, x: x, y: y)
//        }
    }
}
