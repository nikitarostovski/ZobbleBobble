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
    enum State {
        case level
        case menu
    }
    
    var state: State = .menu
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
    
    let screenSize: CGSize
    
    let levelManager: LevelManager
    
    weak var delegate: GameDelegate?
    weak var scrollHolder: ScrollHolder?
    
    var state: GameState
    var cameraState = CameraState()
    
    var currentPack: PackModel? {
        guard 0..<levelManager.allLevelPacks.count ~= state.packIndex else { return nil }
        return levelManager.allLevelPacks[state.packIndex]
    }
    
    var currentLevel: LevelModel? {
        guard let pack = currentPack, 0..<pack.levels.count ~= state.levelIndex else { return nil }
        return pack.levels[state.levelIndex]
    }
    
    var scene: LevelScene?
    var menu: MenuScene?
    
    var stars = [StarBody]()
    var terrains = [TerrainBody]()
    var missles = [MissleBody]()
    
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
        
        self.state = GameState(state: .menu, packIndex: 0, levelIndex: 0)
    }
    
    func update(_ time: CFTimeInterval) {
        if let scene = scene {
            scene.update(time)
        }
    }
    
    func runGame() {
        cameraState.camera = .zero
        cameraState.cameraScale = 1
        
        let scene = LevelScene(game: self)
        self.scene = scene
        self.state.state = .level
        self.menu = nil
        delegate?.gameDidChangeState(self)
    }
    
    func runMenu(isFromLevel: Bool = false) {
        let from = isFromLevel ? Settings.Camera.levelCameraScale : Settings.Camera.levelsMenuCameraScale
        let menu = MenuScene(game: self, from: from)
        self.menu = menu
        self.state.state = .menu
        self.scene = nil
        delegate?.gameDidChangeState(self)
    }
    
    func onTap(at pos: CGPoint) {
        switch state.state {
        case .level:
            scene?.onTap(pos)
        case .menu:
            menu?.onTap(position: pos)
        }
    }
    
    func onSwipe(_ position: CGPoint) {
        switch state.state {
        case .level:
            scene?.onSwipe(position.x)
        case .menu:
            menu?.onSwipe(position.x)
        }
    }
    
    func onExitTap() {
        guard state.state == .level else { return }
        runMenu(isFromLevel: true)
    }
    
    func replace(stars: [StarBody]? = nil, terrains: [TerrainBody]? = nil, missles: [MissleBody]? = nil) {
        if let terrains = terrains {
            self.terrains = terrains
        }
        if let stars = stars {
            self.stars = stars
        }
        if let missles = missles {
            self.missles = missles
        }
    }
}
