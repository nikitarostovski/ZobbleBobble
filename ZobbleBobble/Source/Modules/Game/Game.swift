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

struct GameState {
    enum State {
        case level
        case menu
    }
    
    var state: State = .menu
    var level: Int = 0
    
    var camera: CGPoint
}

final class Game {
    weak var delegate: GameDelegate?
    private let animationDuration: TimeInterval = 0.5
    private(set) var cameraScale: Float = 1
    private(set) var state: GameState
    
    let levelManager: LevelManager
    private var world: World?
    private var menu: Menu?
    
    var backgroundAnchorPositions: UnsafeMutableRawPointer?
    var backgroundAnchorRadii: UnsafeMutableRawPointer?
    var backgroundAnchorColors: UnsafeMutableRawPointer?
    var backgroundAnchorPointCount: Int?
    
    init(delegate: GameDelegate?) {
        let levelManager = LevelManager()
        self.levelManager = levelManager
        self.delegate = delegate
        self.menu = Menu(levels: levelManager.allLevels)
        self.state = GameState(state: .menu, level: 0, camera: .zero)
        
        changeState(to: self.state.state, animated: false)
    }
    
    func update(_ time: CFTimeInterval) {
        world?.update(time)
    }
    
    func changeState(to state: GameState.State, animated: Bool = true) {
        switch state {
        case .menu:
            exitToMenu(number: self.state.level, animated: animated)
        case .level:
            runGame(number: self.state.level, animated: animated)
        }
        self.refreshBackgroundRenderData()
    }
    
    var isSoldComet = false
    
    func gameToScreen(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: (state.camera.x) + CGFloat(cameraScale) * point.x,
                       y: (state.camera.y) + CGFloat(cameraScale) * point.y)
    }
    
    func screenToGame(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: state.camera.x + point.x / CGFloat(cameraScale),
                       y: state.camera.y + point.y / CGFloat(cameraScale))
    }
    
    func onTap(at pos: CGPoint) {
        let pos = screenToGame(pos)
        
        switch state.state {
        case .level:
            let cometType: CometType = .liquid//isSoldComet ? .solid : .liquid
            isSoldComet.toggle()
            let color = Colors.comet(cometType).pickColor()
            
            switch state.state {
            case .level:
                world?.spawnComet(type: cometType, position: pos, radius: cometType.radius, color: color)
            case .menu:
                break
            }
        case .menu:
            self.changeState(to: .level)
        }
    }
    
    func onSwipe(_ position: CGPoint) {
        switch state.state {
        case .level:
            break
        case .menu:
            self.state.camera.x = position.x / CGFloat(cameraScale)
            let position = max(0, min((position.x) / CGFloat(cameraScale), levelManager.levelsTotalWidth))
            if position != 0 {
                let planetIndex = Int(position / levelManager.levelDistance + 0.5)
                if self.state.level != planetIndex {
                    self.state.level = planetIndex
                }
            }
        }
    }
    
    private func runGame(number: Int, animated: Bool) {
        let currentScale: Float = cameraScale
        let currentCamera = state.camera
        let targetScale: Float = 1.0
        let targetCamera = levelManager.allLevels[number].center
        
        let completion = { [weak self] in
            guard let self = self else { return }
            self.cameraScale = targetScale
            self.state.camera.x = targetCamera.x
            self.menu = nil
            self.world = World(level: self.levelManager.allLevels[number])
            self.state.state = .level
            self.delegate?.gameDidChangeState(self)
        }
        
        let animation = { [weak self] (percentage: CGFloat) -> Void in
            guard let self = self else { return }
            self.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
            self.state.camera.x = currentCamera.x + (targetCamera.x - currentCamera.x) * percentage
            self.delegate?.gameDidChangeState(self)
        }
        
        if animated {
            Animator.animate(duraion: animationDuration, step: animation, completion: completion)
        } else {
            completion()
        }
    }
    
    private func exitToMenu(number: Int, animated: Bool) {
        let currentScale: Float = cameraScale
        let currentCamera = state.camera
        let targetScale: Float = 0.4
        let targetCamera = levelManager.allLevels[number].center
        
        self.menu = Menu(levels: levelManager.allLevels)
        self.state.state = .menu
        self.world = nil
        
        let completion = { [weak self] in
            guard let self = self else { return }
            self.cameraScale = targetScale
            self.state.camera = targetCamera
            self.delegate?.gameDidChangeState(self)
        }
        
        let animation = { [weak self] (percentage: CGFloat) -> Void in
            guard let self = self else { return }
            self.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
            self.state.camera.x = currentCamera.x + (targetCamera.x - currentCamera.x) * percentage
            self.delegate?.gameDidChangeState(self)
        }
        
        if animated {
            Animator.animate(duraion: animationDuration, step: animation, completion: completion)
        } else {
            completion()
        }
    }
    
    private func refreshBackgroundRenderData() {
        let levels = levelManager.allLevels
        var outlinePositions: [SIMD2<Float32>] = levels.map { SIMD2<Float32>(Float32($0.center.x), Float32($0.center.y)) }
        var outlineColors: [SIMD4<UInt8>] = levels.map { $0.targetOutline.color }
        var outlineRadii: [Float] = levels.map { Float($0.targetOutline.radius) }
        
        let outlinePositionsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count, alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        outlinePositionsPointer.copyMemory(from: &outlinePositions, byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count)
        
        let outlineRadiiPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.stride * outlineRadii.count, alignment: MemoryLayout<Float>.alignment)
        outlineRadiiPointer.copyMemory(from: &outlineRadii, byteCount: MemoryLayout<Float>.stride * outlineRadii.count)
        
        let outlineColorsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count, alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        outlineColorsPointer.copyMemory(from: &outlineColors, byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count)
        
        self.backgroundAnchorPositions = outlinePositionsPointer
        self.backgroundAnchorRadii = outlineRadiiPointer
        self.backgroundAnchorColors = outlineColorsPointer
        self.backgroundAnchorPointCount = levels.count
    }
}

extension Game: RenderDataSource {
    var cameraX: Float {
        Float(self.state.camera.x)
    }
    
    var cameraY: Float {
        Float(self.state.camera.y)
    }
    
    var renderDataSource: RenderDataSource? {
        switch state.state {
        case .level:
            return world
        case .menu:
            return menu
        }
    }
    var particleRadius: Float {
        renderDataSource?.particleRadius ?? 0
    }
    
    var liquidCount: Int? {
        renderDataSource?.liquidCount
    }
    
    var liquidPositions: UnsafeMutableRawPointer? {
        renderDataSource?.liquidPositions
    }
    
    var liquidVelocities: UnsafeMutableRawPointer? {
        renderDataSource?.liquidVelocities
    }
    
    var liquidColors: UnsafeMutableRawPointer? {
        renderDataSource?.liquidColors
    }
    
    var circleBodyCount: Int? {
        renderDataSource?.circleBodyCount
    }
    
    var circleBodiesPositions: UnsafeMutableRawPointer? {
        renderDataSource?.circleBodiesPositions
    }
    
    var circleBodiesColors: UnsafeMutableRawPointer? {
        renderDataSource?.circleBodiesColors
    }
    
    var circleBodiesRadii: UnsafeMutableRawPointer? {
        renderDataSource?.circleBodiesRadii
    }
    
    
}
