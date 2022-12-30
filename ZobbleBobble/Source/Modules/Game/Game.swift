//
//  Game.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import ZobbleCore
import ZobblePhysics

enum GameState {
    case level(Int)
    case menu(Int)
}

final class Game {
    private(set) var currentLevel = 0
    private(set) var cameraScale: Float = 1
    private(set) var state: GameState
    
    private let levelManager: LevelManager
    private var world: World?
    private var menu: Menu?
    
    init() {
        let levelManager = LevelManager()
        self.levelManager = levelManager
        self.menu = Menu(levels: levelManager.allLevels)
        self.state = .menu(currentLevel)
        
        changeState(to: .menu(currentLevel), animated: false)
    }
    
    func update(_ time: CFTimeInterval) {
        world?.update(time)
    }
    
    func changeState(to state: GameState, animated: Bool = true) {
        switch state {
        case .menu(let number):
            exitToMenu(number: number)
        case .level(let number):
            runGame(number: number)
        }
    }
    
    func onTap(at pos: CGPoint) {
        switch state {
        case .level:
            world?.spawnComet(at: pos, radius: 10, color: Colors.comet.pickColor())
        case .menu:
            break
        }
    }
    
    private func runGame(number: Int) {
        let currentScale: Float = cameraScale
        let targetScale: Float = 1.0
        
        let startDate = Date()
        let duration: TimeInterval = 0.5
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { t in
            let timePassed = Date().timeIntervalSince(startDate)
            if timePassed > duration {
                t.invalidate()
                self.state = .level(number)
                self.world = World(level: self.levelManager.allLevels[number])
            }
            let percentage = timePassed / duration
            self.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
        }
    }
    
    private func exitToMenu(number: Int) {
        menu = Menu(levels: levelManager.allLevels)
        
        let currentScale: Float = cameraScale
        let targetScale: Float = 0.2
        
        let duration: TimeInterval = 0.5
        var timePassed: TimeInterval = 0
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { t in
            timePassed += t.timeInterval
            if timePassed > duration {
                t.invalidate()
                self.state = .menu(number)
                self.world = nil
            }
            let percentage = timePassed / duration
            self.cameraScale = currentScale + (targetScale - currentScale) * Float(percentage)
        }
    }
}

extension Game: RenderDataSource {
    var renderDataSource: RenderDataSource? {
        switch state {
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
