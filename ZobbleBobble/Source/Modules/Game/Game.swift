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
    let levelCenterPoint: CGPoint = CGPoint(x: 0, y: 100)
    
    weak var delegate: GameDelegate?
    weak var scrollHolder: ScrollHolder?
    
    var state: GameState
    
    let worldSize: CGSize
    let levelManager: LevelManager
    
    private var world: World?
    private var menu: Menu?
    
    var backgroundAnchorPositions: UnsafeMutableRawPointer?
    var backgroundAnchorRadii: UnsafeMutableRawPointer?
    var backgroundAnchorColors: UnsafeMutableRawPointer?
    var backgroundAnchorPointCount: Int?
    
    var nextCometType: CometType? {
        get { world?.nextCometType }
        set { world?.nextCometType = newValue! }
    }
    
    init(delegate: GameDelegate?, scrollHolder: ScrollHolder?, worldSize: CGSize) {
        let levelManager = LevelManager()
        self.levelManager = levelManager
        self.worldSize = worldSize
        
        self.delegate = delegate
        self.scrollHolder = scrollHolder
        
        self.state = GameState(state: .menu, packIndex: 0, levelIndex: 0)
    }
    
    func update(_ time: CFTimeInterval) {
        guard let world = world else { return }
        world.update(time)
    }
    
    func runGame() {
        let level = levelManager.allLevelPacks[self.state.packIndex].levels[self.state.levelIndex]
        let world = World(level: level, centerPoint: levelCenterPoint)
        self.world = world
        self.state.state = .level
    }
    
    func runMenu(isFromLevel: Bool = false) {
        let from = isFromLevel ? Menu.levelCameraScale : Menu.levelsMenuCameraScale
        let menu = Menu(game: self, from: from)
        self.menu = menu
        self.state.state = .menu
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
    
//    private func runGame(animated: Bool) {
//        let currentScale: Float = state.cameraScale
//        let currentCamera = state.camera
//        let targetScale = defaultCameraScale
//        let targetCamera = levelCenterPoint
//
//        let animation = { [weak self] (percentage: CGFloat) -> Void in
//            guard let self = self else { return }
//            self.state.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
//            self.state.camera.x = currentCamera.x + (targetCamera.x - currentCamera.x) * percentage
//            self.refreshMenuRenderData()
////            self.delegate?.gameDidChangeState(self)
//        }
//
//        let completion = { [weak self] in
//            guard let self = self else { return }
//            self.state.cameraScale = targetScale
//            self.state.camera.x = targetCamera.x
//            self.menu = nil
//            self.world = World(level: self.levelManager.allLevelPacks[self.state.levelPack].levels[number], centerPoint: self.levelCenterPoint)
//            self.state.state = .level
//            self.refreshMenuRenderData()
//            self.delegate?.gameDidChangeState(self)
//        }
//
//        if animated {
//            Animator.animate(duraion: animationDuration, step: animation, completion: completion)
//        } else {
//            completion()
//        }
//    }
//
//    private func exitToLevelMenu(number: Int, animated: Bool) {
//        let currentScale: Float = state.cameraScale
//        let currentCamera = state.camera
//        let targetScale = levelsMenuCameraScale
//        let targetCamera = levelCenterPoint
//
//        self.menu = Menu(levelPacks: levelManager.allLevelPacks)
//        self.state.state = .menuLevels
//        self.state.camera = .zero
//        self.world = nil
//
//        let animation = { [weak self] (percentage: CGFloat) -> Void in
//            guard let self = self else { return }
//            self.state.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
//            self.state.camera.x = currentCamera.x + (targetCamera.x - currentCamera.x) * percentage
//            self.refreshMenuRenderData()
////            self.delegate?.gameDidChangeState(self)
//        }
//
//        let completion = { [weak self] in
//            guard let self = self else { return }
//            self.state.cameraScale = targetScale
//            self.state.camera = targetCamera
//            self.refreshMenuRenderData()
//            self.delegate?.gameDidChangeState(self)
//        }
//
//        if animated {
//            Animator.animate(duraion: animationDuration, step: animation, completion: completion)
//        } else {
//            completion()
//        }
//    }
//
//    private func exitToPackMenu(number: Int, animated: Bool) {
//        let currentScale: Float = state.cameraScale
//        let currentCamera = state.camera
//        let targetScale = packsMenuCameraScale
//        let targetCamera = levelCenterPoint
//
////        self.menu = Menu(levels: levelManager.allLevels)
//        self.state.state = .menuPacks
//        self.state.camera = .zero
//        self.world = nil
//
//        let animation = { [weak self] (percentage: CGFloat) -> Void in
//            guard let self = self else { return }
//            self.state.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
//            self.state.camera.x = currentCamera.x + (targetCamera.x - currentCamera.x) * percentage
//            self.refreshMenuRenderData()
////            self.delegate?.gameDidChangeState(self)
//        }
//
//        let completion = { [weak self] in
//            guard let self = self else { return }
//            self.state.cameraScale = targetScale
//            self.state.camera = targetCamera
//            self.refreshMenuRenderData()
//            self.delegate?.gameDidChangeState(self)
//            self.state.camera = .zero
//        }
//
//        if animated {
//            Animator.animate(duraion: animationDuration, step: animation, completion: completion)
//        } else {
//            completion()
//        }
//    }
    
    private func refreshMenuRenderData() {
//        let position: CGFloat = state.camera.x / worldSize.width * CGFloat(state.cameraScale) + 0.5
////        let packIndex = state.state == .menuLevels ? state.levelPack : nil
////        let levelIndex = state.state == .menuLevels ? state.level : nil
//
//        let progress = CGFloat(state.cameraScale)
//        let visibleIndex = Int(position)
//
//        if progress >= 1, progress <= 2, visibleIndex != state.level {
//            state.level = visibleIndex
//        } else if visibleIndex != state.levelPack {
//            state.levelPack = visibleIndex
//        }
//
//        self.menu?.updateCamera(worldSize: worldSize,
//                                levelToPackProgress: progress,
//                                currentPagePosition: position,
//                                packIndex: state.levelPack,
//                                levelIndex: state.level,
//                                levelCenterPoint: levelCenterPoint)
    }
    
    private func refreshBackgroundRenderData() {
//        let packs = levelManager.allLevelPacks
//        var outlinePositions: [SIMD2<Float32>] = packs.map { SIMD2<Float32>(Float32($0.center.x), Float32($0.center.y)) }
//        var outlineColors: [SIMD4<UInt8>] = packs.map { $0.targetOutline.color }
//        var outlineRadii: [Float] = packs.map { Float($0.targetOutline.radius) }
//
//        let levels = packs.flatMap { $0.levels }
//        outlinePositions += levels.map { SIMD2<Float32>(Float32($0.center.x), Float32($0.center.y)) }
//        outlineColors += levels.map { $0.targetOutline.color }
//        outlineRadii += levels.map { Float($0.targetOutline.radius) }
//
//        let outlinePositionsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count, alignment: MemoryLayout<SIMD2<Float32>>.alignment)
//        outlinePositionsPointer.copyMemory(from: &outlinePositions, byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count)
//
//        let outlineRadiiPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.stride * outlineRadii.count, alignment: MemoryLayout<Float>.alignment)
//        outlineRadiiPointer.copyMemory(from: &outlineRadii, byteCount: MemoryLayout<Float>.stride * outlineRadii.count)
//
//        let outlineColorsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count, alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
//        outlineColorsPointer.copyMemory(from: &outlineColors, byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count)
//
//        self.backgroundAnchorPositions = outlinePositionsPointer
//        self.backgroundAnchorRadii = outlineRadiiPointer
//        self.backgroundAnchorColors = outlineColorsPointer
//        self.backgroundAnchorPointCount = levels.count
    }
}

extension Game {
    var renderDataSource: RenderDataSource? {
        switch state.state {
        case .level:
            return world
        case .menu:
            return menu
        }
    }
}
