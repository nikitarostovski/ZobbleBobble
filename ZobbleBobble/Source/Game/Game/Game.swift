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

struct GameState {
    /// index of selected pack for level selection mode
    var packIndex: Int
    /// index of level for level mode
    var levelIndex: Int
}

struct CameraState {
    var camera: CGPoint = .zero
    var cameraScale: CGFloat = 1
}

final class Game {
    let levelCenterPoint: CGPoint = CGPoint(x: 0, y: Settings.Camera.levelCenterOffset)
    weak var delegate: GameDelegate?
    weak var scrollHolder: ScrollHolder?
    
    let screenSize: CGSize
    let levelManager: LevelManager
    
    var state: GameState
    var cameraState = CameraState()
    
    // Game objects
    private(set) var visibleScenes: [TransitionableScene]
    
    // Computable properties
    var currentPack: PackModel? {
        guard 0..<levelManager.allLevelPacks.count ~= state.packIndex else { return nil }
        return levelManager.allLevelPacks[state.packIndex]
    }
    
    var currentLevel: LevelModel? {
        guard let pack = currentPack, 0..<pack.levels.count ~= state.levelIndex else { return nil }
        return pack.levels[state.levelIndex]
    }
    
    // MARK: - Methods
    init?(delegate: GameDelegate?, scrollHolder: ScrollHolder?, screenSize: CGSize) {
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
        self.levelManager = levelManager
        self.screenSize = screenSize
        
        self.delegate = delegate
        self.scrollHolder = scrollHolder
        
        self.state = GameState(/*scene: .controlCenter, */packIndex: 0, levelIndex: 0)
        
        let rootScene = ControlCenterScene()
        self.visibleScenes = [rootScene]
        
        rootScene.delegate = self
    }
    
    func update(_ time: CFTimeInterval) {
        visibleScenes.forEach {
            $0.update(time)
        }
    }
    
    func runGame() {
        cameraState.camera = .zero
        cameraState.cameraScale = 1
        
//        let scene = LevelScene(game: self)
//        self.scene = scene
//        self.state.scene = .planet
//        self.menu = nil
        delegate?.gameDidChangeState(self)
    }
    
    func runMenu(isFromLevel: Bool = false) {
//        let from = isFromLevel ? Settings.Camera.levelCameraScale : Settings.Camera.levelsMenuCameraScale
//        let menu = MenuScene(game: self, from: from)
//        self.menu = menu
//        self.state.scene = .controlCenter
//        self.scene = nil
        delegate?.gameDidChangeState(self)
    }
    
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
    
    func onExitTap() {
//        guard state.state == .level else { return }
//        runMenu(isFromLevel: true)
    }
    
//    func replace(stars: [StarBody]? = nil, terrains: [TerrainBody]? = nil, missles: [MissleBody]? = nil) {
//        if let terrains = terrains {
//            self.terrains = terrains
//        }
//        if let stars = stars {
//            self.stars = stars
//        }
//        if let missles = missles {
//            self.missles = missles
//        }
//    }
}

extension Game: TransitionableSceneDelegate {
    func onTransitionableSceneAppendRequest(sender: TransitionableScene, becomesActive: Bool) {
        if becomesActive || visibleScenes.isEmpty {
            visibleScenes.append(sender)
        } else {
            visibleScenes.insert(sender, at: 0)
        }
    }
    
    func onTransitionableSceneRemovalRequest(sender: TransitionableScene) {
        visibleScenes.removeAll(where: { $0 === sender })
    }
}
