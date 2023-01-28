//
//  Menu.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import ZobbleCore

struct MenuState {
    /// progress from level state to menuPacks state [1...3] (1 is level state, 2 is level selection, 3 is pack selection)
    var levelToPackProgress: CGFloat
    /// horizontal scroll position of level in index values (1.5 equals exact middle between indices 1 and 2)
    var currentLevelPagePosition: CGFloat
    /// horizontal scroll position of pack in index values (1.5 equals exact middle between indices 1 and 2)
    var currentPackPagePosition: CGFloat
}

final class Menu {
    static let levelCameraScale: CGFloat = 1
    static let levelsMenuCameraScale: CGFloat = 2
    static let packsMenuCameraScale: CGFloat = 3
    
    private let starLevelScale: CGFloat = 1
    private let starLevelMenuScale: CGFloat = 0.25
    private let starPackMenuScale: CGFloat = 0.5
    
    private let planetLevelScale: CGFloat = 1
    private let planetLevelMenuScale: CGFloat = 0.25
    private let planetPackMenuScale: CGFloat = 0
    
    private let starLevelAngle: CGFloat = CGFloat(90).radians
    private let starLevelMenuAngle: CGFloat = CGFloat(30).radians
    private let starPackMenuAngle: CGFloat = CGFloat(20).radians
    
    private let planetLevelAngle: CGFloat = CGFloat(90).radians
    private let planetLevelMenuAngle: CGFloat = CGFloat(20).radians
    private let planetPackMenuAngle: CGFloat = CGFloat(90).radians
    
    
    private var starCenterLevelMode: CGPoint = .zero
    private var starCenterMenuLevelMode: CGPoint = .zero
    private var starCenterMenuPackMode: CGPoint = .zero
    
    private var planetCenterLevelMode: CGPoint = .zero
    private var planetCenterMenuLevelMode: CGPoint = .zero
    private var planetCenterMenuPackMode: CGPoint = .zero
    
    private var starRadiusScale: CGFloat = 0
    private var planetRadiusScale: CGFloat = 0
    
    private var starCenterPoint: CGPoint = .zero
    private var planetCenterPoint: CGPoint = .zero
    
    private var starAngleBetweenPositions: CGFloat = 0
    private var planetAngleBetweenPositions: CGFloat = 0
    
    private var starRadius: CGFloat = 0
    private var starAnchor: CGPoint = .zero
    
    private var planetRadius: CGFloat = 0
    private var planetAnchor: CGPoint = .zero
    
    private var starCenterAngle: CGFloat = 0
    private var planetCenterAngle: CGFloat = 0
    
    
    private var lastUpdateGameSize: CGSize = .zero
    private var lastUpdateLevelToPackProgress: CGFloat = -1
    private var lastUpdateCurrentPackPagePosition: CGFloat = -1
    private var lastUpdateCurrentLevelPagePosition: CGFloat = -1
    
    
    private var visibleLevelPackIndices: ClosedRange<Int> = 0...0
    private var visibleLevelIndices: ClosedRange<Int> = 0...0
    
    private(set) var state: MenuState
    private weak var game: Game?
    
    var circleBodyCount: Int?
    var circleBodiesPositions: UnsafeMutableRawPointer?
    var circleBodiesColors: UnsafeMutableRawPointer?
    var circleBodiesRadii: UnsafeMutableRawPointer?
    
    var particleRadius: Float = 0
    var liquidFadeModifier: Float = 0
    var liquidCount: Int?
    var liquidPositions: UnsafeMutableRawPointer?
    var liquidVelocities: UnsafeMutableRawPointer?
    var liquidColors: UnsafeMutableRawPointer?
    
//    var backgroundAnchorPointCount: Int? { nil }
//    var backgroundAnchorPoints: UnsafeMutableRawPointer? { nil }
//    var backgroundAnchorRadii: UnsafeMutableRawPointer? { nil }
    
    init(game: Game?, from: CGFloat = levelsMenuCameraScale, to: CGFloat = levelsMenuCameraScale) {
        self.game = game
        self.state = MenuState(levelToPackProgress: from, currentLevelPagePosition: 0, currentPackPagePosition: 0)
        
        if (to == from) {
            updateScroll()
            updateRenderData()
            return
        }
        switch to {
        case Self.levelCameraScale:
                transitionToLevel()
        case Self.levelsMenuCameraScale:
            transitionToLevelSelection()
        case Self.packsMenuCameraScale:
            transitionToPackSelection()
        default:
            break
        }
    }
    
    func onTap(position: CGPoint) {
        // level selection
        if state.levelToPackProgress <= 2 {
            let level = Int(state.currentLevelPagePosition)
            game!.state.levelIndex = level
            
            let pack = game!.levelManager.allLevelPacks[game!.state.packIndex]
            let packPos = convertStarPosition(game!.state.packIndex)
            let packRadius = convertStarRadius(pack.targetOutline.radius)
            if packPos.distance(to: position) <= packRadius {
                // go back to star selection
                transitionToPackSelection()
                return
            }
            
            let packLevels = game!.levelManager.allLevelPacks[game!.state.packIndex].levels
            for i in packLevels.indices {
                let levelPos = convertPlanetPosition(i)
                let levelRadius = convertPlanetRadius(packLevels[i].targetOutline.radius)
                if (levelPos.distance(to: position) <= levelRadius) {
                    // run level
                    transitionToLevel()
                    return
                }
            }
        // pack selection
        } else {
            let pack = Int(state.currentPackPagePosition)
            game!.state.packIndex = pack
            game!.state.levelIndex = 0
            
            for pack in game!.levelManager.allLevelPacks {
                let packPos = convertStarPosition(pack.number)
                let packRadius = convertStarRadius(pack.targetOutline.radius)
                if packPos.distance(to: position) <= packRadius {
                    // go inside pack
                    transitionToLevelSelection()
                    return
                }
            }
        }
    }
    
    func onSwipe(_ offset: CGFloat) {
        guard let game = game else { return }
        
        if state.levelToPackProgress == 2 {
            // level selection
            state.currentLevelPagePosition = offset / game.screenSize.width
        } else if state.levelToPackProgress == 3 {
            // pack selection
            state.currentPackPagePosition = offset / game.screenSize.width
        }
        updateRenderData()
    }
    
    private var visibleLevelPacks: [LevelPack] {
        Array(game!.levelManager.allLevelPacks[visibleLevelPackIndices])
    }
    
    private var visibleLevels: [Level] {
        Array(game!.levelManager.allLevelPacks[game!.state.packIndex].levels[visibleLevelIndices])
    }
    
    private func transitionToLevel() {
        let startProgress = state.levelToPackProgress
        let targetProgress = Self.levelCameraScale
        
        Animator.animate(duraion: Settings.menuAnimationDuration, easing: Settings.menuAnimationEasing) { [weak self] percentage in
            guard let self = self else { return }
            self.state.levelToPackProgress = startProgress + (targetProgress - startProgress) * percentage
            self.updateRenderData()
        } completion: { [weak self] in
            guard let self = self else { return }
            self.state.levelToPackProgress = targetProgress
            self.updateRenderData()
            self.game!.runGame()
        }
    }
    
    private func transitionToLevelSelection() {
        let startProgress = state.levelToPackProgress
        let targetProgress = Self.levelsMenuCameraScale
        
        state.currentLevelPagePosition = CGFloat(game!.state.levelIndex)
        
        Animator.animate(duraion: Settings.menuAnimationDuration, easing: Settings.menuAnimationEasing) { [weak self] percentage in
            guard let self = self else { return }
            self.state.levelToPackProgress = startProgress + (targetProgress - startProgress) * percentage
            self.updateRenderData()
        } completion: { [weak self] in
            guard let self = self else { return }
            self.state.levelToPackProgress = targetProgress
            self.updateScroll()
            self.updateRenderData()
        }
    }
    
    private func transitionToPackSelection() {
        let startProgress = state.levelToPackProgress
        let targetProgress = Self.packsMenuCameraScale
        
        state.currentPackPagePosition = CGFloat(game!.state.packIndex)
        
        Animator.animate(duraion: Settings.menuAnimationDuration, easing: Settings.menuAnimationEasing) { [weak self] percentage in
            guard let self = self else { return }
            self.state.levelToPackProgress = startProgress + (targetProgress - startProgress) * percentage
            self.updateRenderData()
        } completion: { [weak self] in
            guard let self = self else { return }
            self.state.levelToPackProgress = targetProgress
            self.updateScroll()
            self.updateRenderData()
        }
    }
    
    private func updateScroll() {
        let pageCount: Int
        let selectedPage: Int
        if state.levelToPackProgress < 3 {
            // level selection
            let pack = game!.levelManager.allLevelPacks[game!.state.packIndex]
            pageCount = pack.levels.count
            selectedPage = game!.state.levelIndex
        } else {
            // pack selection
            pageCount = game!.levelManager.allLevelPacks.count
            selectedPage = game!.state.packIndex
        }
        game?.scrollHolder?.updateScrollPosition(pageCount: pageCount, selectedPage: selectedPage)
    }
    
    private func updateRenderData() {
        updatePositionsDataIfNeeded()
        updateCirclesData()
        updateLiquidData()
    }
    
    private func isPointVisible(_ point: CGPoint, radius: CGFloat) -> Bool {
        let left = -game!.screenSize.width / 2 - radius
        let right = game!.screenSize.width / 2 + radius
        let top = -game!.screenSize.height / 2 - radius
        let bottom = game!.screenSize.height / 2 + radius
        
        return left...right ~= point.x && top...bottom ~= point.y
    }
    
    private func updatePositionsDataIfNeeded() {
        if game!.screenSize != lastUpdateGameSize {
            lastUpdateGameSize = game!.screenSize
            
            starCenterLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y - game!.screenSize.height * 0.6)
            starCenterMenuLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y - game!.screenSize.height * 0.35)
            starCenterMenuPackMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y + game!.screenSize.height * 0.1)
            
            planetCenterLevelMode = game!.levelCenterPoint
            planetCenterMenuLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y - 10)
            planetCenterMenuPackMode = starCenterMenuPackMode
            
            starRadius = game!.screenSize.height
            planetRadius = game!.screenSize.height / 2
        }
        
        if (lastUpdateLevelToPackProgress != state.levelToPackProgress) {
            lastUpdateLevelToPackProgress = state.levelToPackProgress
            
            if state.levelToPackProgress <= 2 {
                // level selection
                let p = state.levelToPackProgress - 1
                starRadiusScale = starLevelScale + p * (starLevelMenuScale - starLevelScale)
                planetRadiusScale = planetLevelScale + p * (planetLevelMenuScale - planetLevelScale)
                starCenterPoint = CGPoint(x: starCenterLevelMode.x + p * (starCenterMenuLevelMode.x - starCenterLevelMode.x),
                                          y: starCenterLevelMode.y + p * (starCenterMenuLevelMode.y - starCenterLevelMode.y))
                planetCenterPoint = CGPoint(x: planetCenterLevelMode.x + p * (planetCenterMenuLevelMode.x - planetCenterLevelMode.x),
                                            y: planetCenterLevelMode.y + p * (planetCenterMenuLevelMode.y - planetCenterLevelMode.y))
                starAngleBetweenPositions = starLevelAngle + p * (starLevelMenuAngle - starLevelAngle)
                planetAngleBetweenPositions = planetLevelAngle + p * (planetLevelMenuAngle - planetLevelAngle)
            } else {
                // pack selection
                let p = state.levelToPackProgress - 2
                starRadiusScale = starLevelMenuScale + p * (starPackMenuScale - starLevelMenuScale)
                planetRadiusScale = planetLevelMenuScale + p * (planetPackMenuScale - planetLevelMenuScale)
                starCenterPoint = CGPoint(x: starCenterMenuLevelMode.x + p * (starCenterMenuPackMode.x - starCenterMenuLevelMode.x),
                                          y: starCenterMenuLevelMode.y + p * (starCenterMenuPackMode.y - starCenterMenuLevelMode.y))
                planetCenterPoint = CGPoint(x: planetCenterMenuLevelMode.x + p * (planetCenterMenuPackMode.x - planetCenterMenuLevelMode.x),
                                            y: planetCenterMenuLevelMode.y + p * (planetCenterMenuPackMode.y - planetCenterMenuLevelMode.y))
                starAngleBetweenPositions = starLevelMenuAngle + p * (starPackMenuAngle - starLevelMenuAngle)
                planetAngleBetweenPositions = planetLevelMenuAngle + p * (planetPackMenuAngle - planetLevelMenuAngle)
            }
            
            starAnchor = CGPoint(x: starCenterPoint.x, y: starCenterPoint.y - starRadius)
            planetAnchor = CGPoint(x: planetCenterPoint.x, y: planetCenterPoint.y - planetRadius)
            starCenterAngle = starCenterPoint.angle(to: starAnchor).radians
            planetCenterAngle = planetCenterPoint.angle(to: planetAnchor).radians
        }
        
        if lastUpdateCurrentPackPagePosition != state.currentPackPagePosition {
            lastUpdateCurrentPackPagePosition = state.currentPackPagePosition
            let packCurrent = state.currentPackPagePosition
            let packCount = game!.levelManager.allLevelPacks.count
            
            let packVisibilityIndexShift: CGFloat = 1
            let packStart = max(0, min(packCount - 1, Int(floor(packCurrent - packVisibilityIndexShift))))
            let packEnd = max(0, min(packCount - 1, Int(ceil(packCurrent + packVisibilityIndexShift))))
            visibleLevelPackIndices = packStart...packEnd
        }
        
        if lastUpdateCurrentLevelPagePosition != state.currentLevelPagePosition {
            lastUpdateCurrentLevelPagePosition = state.currentLevelPagePosition
            let levelCurrent = state.currentLevelPagePosition
            let levelCount = game!.levelManager.allLevelPacks[game!.state.packIndex].levels.count
            
            let levelVisibilityIndexShift: CGFloat = 2
            let levelStart = max(0, min(levelCount - 1, Int(floor(levelCurrent - levelVisibilityIndexShift))))
            let levelEnd = max(0, min(levelCount - 1, Int(ceil(levelCurrent + levelVisibilityIndexShift))))
            visibleLevelIndices = levelStart...levelEnd
        }
    }
    
    private func updateLiquidData() {
        guard 1...3 ~= state.levelToPackProgress else { return }
        
        var allPositions = [SIMD2<Float32>]()
        var allVelocities = [SIMD2<Float32>]()
        var allRadii = [Float32]()
        var allColors = [SIMD4<UInt8>]()
        
        if (state.levelToPackProgress < 3) {
            for level in visibleLevels {
                for (i, shape) in level.initialShapes.enumerated() {
                    let point = convertPlanetShapePosition(level.number, shapeIndex: i)
                    let radius = self.convertPlanetRadius(CGFloat(shape.radius))
                    
                    if isPointVisible(point, radius: radius) {
                        allPositions.append(SIMD2<Float32>(Float32(point.x), Float32(point.y)))
                        allVelocities.append(SIMD2<Float32>(Float32(0), Float32(0)))
                        allColors.append(shape.color.simdColor)
                        allRadii.append(Float(radius))
                    }
                }
            }
        }
        
        
        let positions = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count,
                                                         alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        positions.copyMemory(from: &allPositions,
                             byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count)
        
        let velocities = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * allVelocities.count,
                                                          alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        velocities.copyMemory(from: &allVelocities,
                              byteCount: MemoryLayout<SIMD2<Float32>>.stride * allVelocities.count)
        
        let radii = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.stride * allRadii.count,
                                                     alignment: MemoryLayout<Float>.alignment)
        radii.copyMemory(from: &allRadii,
                         byteCount: MemoryLayout<Float>.stride * allRadii.count)
        
        let colors = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count,
                                                      alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        colors.copyMemory(from: &allColors,
                          byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count)
        
        self.liquidPositions = positions
        self.liquidVelocities = velocities
        self.liquidColors = colors
        self.liquidCount = allPositions.count
        self.particleRadius = Float(self.convertPlanetRadius(Settings.particleRadius))
    }
    
    private func updateCirclesData() {
        guard 1...3 ~= state.levelToPackProgress else { return }
        
        let visibleLevelPacks = visibleLevelPacks
        
        var allPositions = [SIMD2<Float32>]()
        var allVelocities = [SIMD2<Float32>]()
        var allRadii = [Float32]()
        var allColors = [SIMD4<UInt8>]()
        
        for pack in visibleLevelPacks {
            let point = self.convertStarPosition(pack.number)
            let color = pack.targetOutline.color
            let radius = self.convertStarRadius(pack.targetOutline.radius)
            
            if isPointVisible(point, radius: radius) {
                allPositions.append(SIMD2<Float32>(Float32(point.x), Float32(point.y)))
                allVelocities.append(SIMD2<Float32>(Float32(0), Float32(0)))
                allRadii.append(Float32(radius))
                allColors.append(color)
            }
        }
        
        let positions = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count,
                                                         alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        positions.copyMemory(from: &allPositions,
                             byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count)
        
        let radii = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride * allRadii.count,
                                                     alignment: MemoryLayout<Float32>.alignment)
        radii.copyMemory(from: &allRadii,
                         byteCount: MemoryLayout<Float32>.stride * allRadii.count)
        
        let colors = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count,
                                                      alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        colors.copyMemory(from: &allColors,
                          byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count)
        
        
        self.circleBodiesPositions = positions
        self.circleBodiesRadii = radii
        self.circleBodiesColors = colors
        self.circleBodyCount = allPositions.count
    }
}

// Position calculations

extension Menu {
    private func convertStarPosition(_ index: Int) -> CGPoint {
        var distToCenter: CGFloat = 0
        if state.levelToPackProgress > 2 {
            distToCenter = CGFloat(index) - state.currentPackPagePosition
        } else {
            distToCenter = CGFloat(index) - CGFloat(game!.state.packIndex)
        }
        let targetAngle = starCenterAngle + distToCenter * starAngleBetweenPositions
        let x = starRadius * cos(targetAngle) - starAnchor.x
        let y = starRadius * sin(targetAngle) - starAnchor.y
        return CGPoint(x: x, y: y)
    }
    
    private func convertStarRadius(_ radius: CGFloat) -> CGFloat {
        radius * starRadiusScale
    }
    
    private func convertPlanetPosition(_ index: Int) -> CGPoint {
        var distToCenter: CGFloat = 0
        if state.levelToPackProgress > 1, state.levelToPackProgress < 3 {
            distToCenter = CGFloat(index) - state.currentLevelPagePosition
        }
        let targetAngle = planetCenterAngle + distToCenter * planetAngleBetweenPositions
        let x = planetRadius * cos(targetAngle) - planetAnchor.x
        let y = planetRadius * sin(targetAngle) - planetAnchor.y
        return CGPoint(x: x, y: y)
    }
    
    private func convertPlanetRadius(_ radius: CGFloat) -> CGFloat {
        radius * planetRadiusScale
    }
    
    private func convertPlanetShapePosition(_ levelIndex: Int, shapeIndex: Int) -> CGPoint {
        let level = game!.levelManager.allLevelPacks[game!.state.packIndex].levels[levelIndex]
        let levelPosition = convertPlanetPosition(levelIndex)
        
        let shape = level.initialShapes[shapeIndex]
        return CGPoint(x: levelPosition.x + shape.position.x * planetRadiusScale, y: levelPosition.y + shape.position.y * planetRadiusScale)
    }
}

extension Menu: RenderDataSource {
    var backgroundAnchorRadii: UnsafeMutableRawPointer? {
        nil
    }
    
    var backgroundAnchorPointCount: Int? {
        nil
    }
    
    var cameraX: Float {
        0
    }
    
    var cameraY: Float {
        0
    }
    
    var cameraScale: Float {
        1
    }
    
    var cameraAngle: Float {
        0
    }
    
    var backgroundAnchorPositions: UnsafeMutableRawPointer? {
        nil
    }
    
    var backgroundAnchorColors: UnsafeMutableRawPointer? {
        nil
    }
}
