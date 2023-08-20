//
//  Game.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import Levels

protocol GameDelegate: AnyObject {
    func gameDidChangeState(_ game: Game)
}

protocol ScrollHolder: AnyObject {
    func updateScrollPosition(pageCount: Int, selectedPage: Int)
}

final class Game: RenderDataSource {
    weak var delegate: GameDelegate?
    weak var scrollHolder: ScrollHolder?
    
    private(set) var safeArea: CGRect = .zero
    private(set) var screenSize: CGSize = .zero
    private(set) var screenScale: CGFloat = 1
    
    private(set) var visibleScenes: [Scene]
    private(set) var player: PlayerModel
    
    // MARK: - Methods
    
    init?(delegate: GameDelegate?, scrollHolder: ScrollHolder?) {
        let levelManager: LevelManager
        if let levelDataPath = Bundle(for: LevelManager.self).path(forResource: "/Data/Levels", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: levelDataPath), options: .mappedIfSafe)
                levelManager = try LevelManager(levelData: data)
            } catch {
                return nil
            }
        } else {
            return nil
        }
        
        self.delegate = delegate
        self.scrollHolder = scrollHolder
        self.player = PlayerModel(credits: 1200)
        self.visibleScenes = []
        
        //
        let pack = levelManager.allLevelPacks[0]
        pack.levels.forEach {
            let planet = PlanetModel(level: $0, particleRadius: pack.particleRadius)
            let container = ContainerModel(level: $0)
            
            addPlanet(planet)
            addContainer(container)
        }
        loadContainer(0)
        //
        
        let rootScene = ControlCenterScene(game: self, size: screenSize, safeArea: safeArea, screenScale: screenScale, opacity: 1)
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
}

// MARK: - Lifecycle

extension Game: GameInteractive {
    func containerFinished() {
        removeContainer(nil)
    }
    
    private func addPlanet(_ planet: PlanetModel) {
        player.availablePlanets.append(planet)
    }
    
    private func addContainer(_ container: ContainerModel) {
        player.ship.containers.append(container)
    }
    
    private func removeContainer(_ index: Int?) {
        guard let index = index ?? player.ship.loadedContainerIndex else { return }
        
        if player.ship.loadedContainerIndex == index {
            player.ship.loadedContainerIndex = nil
        }
        player.ship.containers.remove(at: index)
        
        // autoload next
        loadContainer(0)
    }
    
    private func loadContainer(_ index: Int) {
        guard 0..<player.ship.containers.count ~= index else { return }
        player.ship.loadedContainerIndex = index
    }
}

// MARK: - Controls

extension Game {
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
    
    func onSwipe(_ position: CGPoint) {
//        switch state.state {
//        case .level:
//            scene?.onSwipe(position.x)
//        case .menu:
//            menu?.onSwipe(position.x)
//        }
    }
}

extension Game: TransitionableSceneDelegate {
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
