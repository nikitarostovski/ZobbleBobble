//
//  Game.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation

final class MainGame: RenderDataSource {
    private(set) var safeArea: CGRect
    private(set) var screenSize: CGSize
    private(set) var screenScale: CGFloat
    
    private(set) var visibleScenes: [Scene]
    private(set) var player: PlayerModel
    
    private let containerService: ContainerService
    private let planetService: PlanetService
    
    // MARK: - Methods
    
    init(screenSize: CGSize = .zero, safeArea: CGRect = .zero, screenScale: CGFloat = 1) {
        self.safeArea = safeArea
        self.screenSize = screenSize
        self.screenScale = screenScale
        self.player = PlayerModel()
        self.visibleScenes = []
        self.planetService = PlanetService()
        self.containerService = ContainerService()
        
        configurePlayer()
        
//        let rootScene = PlanetSelectionScene(game: self, size: screenSize, safeArea: safeArea, screenScale: screenScale, opacity: 1)
//        let rootScene = ControlCenterScene(game: self, size: screenSize, safeArea: safeArea, screenScale: screenScale, opacity: 1)
        let rootScene = PlanetScene(game: self, size: screenSize, safeArea: safeArea, screenScale: screenScale, opacity: 1)
        rootScene.transitionDelegate = self
        visibleScenes = [rootScene]
    }
    
    func updateSceneSize(newScreenSize: CGSize, newSafeArea: CGRect, newScreenScale: CGFloat) {
        if screenSize != newScreenSize {
            screenSize = newScreenSize
        }
        if safeArea != newSafeArea {
            safeArea = newSafeArea
        }
        if screenScale != newScreenScale {
            screenScale = newScreenScale
        }
        visibleScenes.forEach { $0.onSizeChanged(screenSize, newSafeArea: safeArea, newScreenScale: screenScale) }
    }
    
    func update(_ time: CFTimeInterval) {
        visibleScenes.forEach { scene in
            scene.update(time)
        }
    }
    
    private func configurePlayer() {
        // initial setup
        player.credits = 1200
        
        let initialContainers = containerService.getAvaialableContainers(for: player)
        let initialPlanets = planetService.getAvaialablePlanets(for: player)
        
        initialContainers.forEach {
            addContainer($0)
        }
        
        initialPlanets.forEach {
            addPlanet($0)
        }
        
        selectPlanet(0)
        selectContainer(0)
    }
}

// MARK: - Lifecycle

extension MainGame: Game {
    func addContainer(_ container: ContainerModel) {
        player.containers.append(container)
    }
    
    @discardableResult
    func removeContainer(_ index: Int) -> Bool {
        guard 0..<player.containers.count ~= index else { return false }
        player.containers.remove(at: index)
        return true
    }
    
    @discardableResult
    func selectContainer(_ index: Int) -> Bool {
        guard 0..<player.containers.count ~= index else { return false }
        player.selectedContainerIndex = index
        return true
    }
    
    func clearSelectedContainer() {
        player.selectedContainerIndex = nil
    }
    
    func addPlanet(_ planet: PlanetModel) {
        player.planets.append(planet)
    }
    
    @discardableResult
    func removePlanet(_ index: Int) -> Bool {
        guard 0..<player.planets.count ~= index else { return false }
        player.planets.remove(at: index)
        return true
    }
    
    @discardableResult
    func selectPlanet(_ index: Int) -> Bool {
        guard 0..<player.planets.count ~= index else { return false }
        player.selectedPlanetIndex = index
        return true
    }
    
    func clearSelectedPlanet() {
        player.selectedPlanetIndex = nil
    }
}

// MARK: - Controls

extension MainGame {
    func onTouchDown(pos: CGPoint) {
        let posNorm = CGPoint(x: pos.x / screenSize.width, y: pos.y / screenSize.height)
        visibleScenes.forEach {
            if $0.hitTest(pos: posNorm) {
                $0.onTouchDown(pos: posNorm)
            }
        }
    }
    
    func onTouchMove(pos: CGPoint) {
        let posNorm = CGPoint(x: pos.x / screenSize.width, y: pos.y / screenSize.height)
        visibleScenes.forEach {
            if $0.hitTest(pos: posNorm) {
                $0.onTouchMove(pos: posNorm)
            }
        }
    }
    
    func onTouchUp(pos: CGPoint) {
        let posNorm = CGPoint(x: pos.x / screenSize.width, y: pos.y / screenSize.height)
        visibleScenes.forEach {
            if $0.hitTest(pos: posNorm) {
                $0.onTouchUp(pos: posNorm)
            }
        }
    }
}

extension MainGame: TransitionableSceneDelegate {
    func onTransitionableSceneAppendRequest(sender: Scene, becomesActive: Bool) {
        if becomesActive || visibleScenes.isEmpty {
            visibleScenes.append(sender)
        } else {
            visibleScenes.insert(sender, at: 0)
        }
    }
    
    func onTransitionableSceneRemovalRequest(sender: Scene) {
        visibleScenes.removeAll(where: { $0 === sender })
    }
}
