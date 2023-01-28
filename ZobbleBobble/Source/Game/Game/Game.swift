//
//  Game.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import ZobbleCore
import ZobblePhysics

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

final class Game {
    let levelCenterPoint: CGPoint = CGPoint(x: 0, y: Settings.levelCenterOffset)
    
    weak var delegate: GameDelegate?
    weak var scrollHolder: ScrollHolder?
    
    var state: GameState
    
    let screenSize: CGSize
    let renderSize: CGSize
    
    let levelManager: LevelManager
    
    private var background: Background?
    private var world: World?
    private var menu: Menu?
    
    var nextCometType: CometType? {
        get { world?.nextCometType }
        set { world?.nextCometType = newValue! }
    }
    
    init(delegate: GameDelegate?, scrollHolder: ScrollHolder?, screenSize: CGSize, renderSize: CGSize) {
        let levelManager = LevelManager(particleRadius: Settings.particleRadius)
        self.levelManager = levelManager
        self.screenSize = screenSize
        self.renderSize = renderSize
        
        self.delegate = delegate
        self.scrollHolder = scrollHolder
        
        self.state = GameState(state: .menu, packIndex: 0, levelIndex: 0)
        
        setupBackground()
    }
    
    func update(_ time: CFTimeInterval) {
        background?.updateRenderData()
        if let world = world {
            world.update(time)
        }
    }
    
    func runGame() {
        let level = levelManager.allLevelPacks[self.state.packIndex].levels[self.state.levelIndex]
        let world = World(game: self, level: level, particleRadius: Settings.particleRadius)
        self.world = world
        self.state.state = .level
        self.menu = nil
        background?.objectPositionProvider = world
    }
    
    func runMenu(isFromLevel: Bool = false) {
        let from = isFromLevel ? Menu.levelCameraScale : Menu.levelsMenuCameraScale
        let menu = Menu(game: self, from: from)
        self.menu = menu
        self.state.state = .menu
        self.world = nil
        background?.objectPositionProvider = menu
    }
    
    func onTap(at pos: CGPoint) {
        switch state.state {
        case .level:
            world?.onTap(pos)
        case .menu:
            menu?.onTap(position: pos)
        }
    }
    
    func onSwipe(_ position: CGPoint) {
        switch state.state {
        case .level:
            world?.onSwipe(position.x)
        case .menu:
            menu?.onSwipe(position.x)
        }
    }
    
    func onExitTap() {
        guard state.state == .level else { return }
        runMenu(isFromLevel: true)
    }
    
    private func setupBackground() {
        let background = Background(game: self)
        self.background = background
    }
}

extension Game {
    var backgroundDataSource: BackgroundRenderDataSource? {
        return background
    }
    
    var objectsDataSource: ObjectRenderDataSource? {
        switch state.state {
        case .level:
            return world
        case .menu:
            return menu
        }
    }
    
    var cameraDataSource: CameraRenderDataSource? {
        switch state.state {
        case .level:
            return world
        case .menu:
            return menu
        }
    }
}
