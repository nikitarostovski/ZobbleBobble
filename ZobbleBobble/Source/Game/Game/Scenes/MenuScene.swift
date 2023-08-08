//
//  Menu.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import Levels

struct MenuState {
    /// progress from level state to menuPacks state [1...3] (1 is level state, 2 is level selection, 3 is pack selection)
    var levelToPackProgress: CGFloat
    /// horizontal scroll position of level in index values (1.5 equals exact middle between indices 1 and 2)
    var currentLevelPagePosition: CGFloat
    /// horizontal scroll position of pack in index values (1.5 equals exact middle between indices 1 and 2)
    var currentPackPagePosition: CGFloat
}

final class MenuScene {
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
    
    private(set) var visibleLevelPackIndices: ClosedRange<Int> = 0...0
    private(set) var visibleLevelIndices: ClosedRange<Int> = 0...0
    
    private var lastUpdateVisibleLevelPackIndices: ClosedRange<Int> = -1 ... -1
    
    private(set) var state: MenuState
    private weak var game: Game?
    
    private weak var terrainBody: TerrainBody?
    private var stars: [StarBody] {
        game?.stars ?? []
    }
    
    var visibleStars: [StarBody] {
        let visible = visibleLevelPackIndices
        let allStars = stars
        guard visible.lowerBound >= 0, visible.upperBound < stars.count else { return [] }
        return Array(allStars[visibleLevelPackIndices])
    }
    
    init(game: Game, from: CGFloat = Settings.Camera.levelsMenuCameraScale, to: CGFloat = Settings.Camera.levelsMenuCameraScale) {
        self.game = game
        self.state = MenuState(levelToPackProgress: from, currentLevelPagePosition: 0, currentPackPagePosition: 0)
        
        let starBodies = game.levelManager.allLevelPacks.map { pack in
            if let found = game.stars.first(where: { $0.pack == pack }) {
                return found
            }
            return StarBody(game: game, pack: pack)
        }
    
        let terrainBody = TerrainBody(physicsWorld: nil, uniqueMaterials: Array(Set(visibleLevels.flatMap { $0.allMaterials })))
        self.terrainBody = terrainBody
        game.replace(stars: starBodies, terrains: [terrainBody], missles: [])
        
        if (to == from) {
            updateScroll()
            updateRenderData()
            return
        }
        switch to {
        case Settings.Camera.levelCameraScale:
            transitionToLevel()
        case Settings.Camera.levelsMenuCameraScale:
            transitionToLevelSelection()
        case Settings.Camera.packsMenuCameraScale:
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
            
            let pack = game!.currentPack!
            let packPos = convertStarPosition(game!.state.packIndex) ?? .zero
            let packRadius = convertStarRadius(pack.radius) ?? 0
            if packPos.distance(to: position) <= packRadius {
                // go back to star selection
                transitionToPackSelection()
                return
            }
            
            let packLevels = game!.currentPack!.levels
            for i in packLevels.indices {
                let levelPos = convertPlanetPosition(i) ?? .zero
                let levelRadius = convertPlanetRadius(packLevels[i].gravityRadius) ?? 0
                if (levelPos.distance(to: position) <= levelRadius) {
                    // run level
                    transitionToLevel()
                    return
                }
            }
        // pack selection
        } else {
            game!.state.packIndex = Int(state.currentPackPagePosition)
            game!.state.levelIndex = 0
            
            for (i, pack) in game!.levelManager.allLevelPacks.enumerated() {
                let packPos = convertStarPosition(i) ?? .zero
                let packRadius = convertStarRadius(pack.radius) ?? 0
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
    
    private var visibleLevelPacks: [PackModel] {
        Array(game!.levelManager.allLevelPacks[visibleLevelPackIndices])
    }
    
    private var visibleLevels: [LevelModel] {
        Array(game!.currentPack!.levels[visibleLevelIndices])
    }
    
    private func transitionToLevel() {
        let startProgress = state.levelToPackProgress
        let targetProgress = Settings.Camera.levelCameraScale
        
        Animator.animate(duraion: Settings.Camera.menuAnimationDuration, easing: Settings.Camera.menuAnimationEasing) { [weak self] percentage in
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
        let currentStar = stars[game!.state.packIndex]
        
        let startProgress = state.levelToPackProgress
        let targetProgress = Settings.Camera.levelsMenuCameraScale
        
        let startMissle = currentStar.state.currentMissleIndex
        let targetMissle = CGFloat(0)
        
        state.currentLevelPagePosition = CGFloat(game!.state.levelIndex)
        
        Animator.animate(duraion: Settings.Camera.menuAnimationDuration, easing: Settings.Camera.menuAnimationEasing) { [weak self] percentage in
            guard let self = self else { return }
            self.state.levelToPackProgress = startProgress + (targetProgress - startProgress) * percentage
            currentStar.state.currentMissleIndex = startMissle + (targetMissle - startMissle) * percentage
            self.updateRenderData()
        } completion: { [weak self] in
            guard let self = self else { return }
            self.state.levelToPackProgress = targetProgress
            currentStar.state.currentMissleIndex = targetMissle
            self.updateScroll()
            self.updateRenderData()
        }
    }
    
    private func transitionToPackSelection() {
        let startProgress = state.levelToPackProgress
        let targetProgress = Settings.Camera.packsMenuCameraScale
        
        state.currentPackPagePosition = CGFloat(game!.state.packIndex)
        
        Animator.animate(duraion: Settings.Camera.menuAnimationDuration, easing: Settings.Camera.menuAnimationEasing) { [weak self] percentage in
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
            pageCount = game!.currentPack!.levels.count
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
        updateStarsData()
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
            
            starCenterLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y + Settings.Camera.starCenterOffset)
            starCenterMenuLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y + game!.screenSize.height * 0.35)
            starCenterMenuPackMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y - game!.screenSize.height * 0.1)
            
            planetCenterLevelMode = game!.levelCenterPoint
            planetCenterMenuLevelMode = CGPoint(x: game!.levelCenterPoint.x, y: game!.levelCenterPoint.y)
            planetCenterMenuPackMode = starCenterMenuPackMode
            
            starRadius = game!.screenSize.height
            planetRadius = game!.screenSize.height / 2
        }
        
        if (lastUpdateLevelToPackProgress != state.levelToPackProgress) {
            lastUpdateLevelToPackProgress = state.levelToPackProgress
            
            if state.levelToPackProgress <= 2 {
                // level selection
                let p = state.levelToPackProgress - 1
                starRadiusScale = Settings.Camera.starLevelScale + p * (Settings.Camera.starLevelMenuScale - Settings.Camera.starLevelScale)
                planetRadiusScale = Settings.Camera.planetLevelScale + p * (Settings.Camera.planetLevelMenuScale - Settings.Camera.planetLevelScale)
                starCenterPoint = CGPoint(x: starCenterLevelMode.x + p * (starCenterMenuLevelMode.x - starCenterLevelMode.x),
                                          y: starCenterLevelMode.y + p * (starCenterMenuLevelMode.y - starCenterLevelMode.y))
                planetCenterPoint = CGPoint(x: planetCenterLevelMode.x + p * (planetCenterMenuLevelMode.x - planetCenterLevelMode.x),
                                            y: planetCenterLevelMode.y + p * (planetCenterMenuLevelMode.y - planetCenterLevelMode.y))
                starAngleBetweenPositions = Settings.Camera.starLevelAngle + p * (Settings.Camera.starLevelMenuAngle - Settings.Camera.starLevelAngle)
                planetAngleBetweenPositions = Settings.Camera.planetLevelAngle + p * (Settings.Camera.planetLevelMenuAngle - Settings.Camera.planetLevelAngle)
            } else {
                // pack selection
                let p = state.levelToPackProgress - 2
                starRadiusScale = Settings.Camera.starLevelMenuScale + p * (Settings.Camera.starPackMenuScale - Settings.Camera.starLevelMenuScale)
                planetRadiusScale = Settings.Camera.planetLevelMenuScale + p * (Settings.Camera.planetPackMenuScale - Settings.Camera.planetLevelMenuScale)
                starCenterPoint = CGPoint(x: starCenterMenuLevelMode.x + p * (starCenterMenuPackMode.x - starCenterMenuLevelMode.x),
                                          y: starCenterMenuLevelMode.y + p * (starCenterMenuPackMode.y - starCenterMenuLevelMode.y))
                planetCenterPoint = CGPoint(x: planetCenterMenuLevelMode.x + p * (planetCenterMenuPackMode.x - planetCenterMenuLevelMode.x),
                                            y: planetCenterMenuLevelMode.y + p * (planetCenterMenuPackMode.y - planetCenterMenuLevelMode.y))
                starAngleBetweenPositions = Settings.Camera.starLevelMenuAngle + p * (Settings.Camera.starPackMenuAngle - Settings.Camera.starLevelMenuAngle)
                planetAngleBetweenPositions = Settings.Camera.planetLevelMenuAngle + p * (Settings.Camera.planetPackMenuAngle - Settings.Camera.planetLevelMenuAngle)
            }
            
            starAnchor = CGPoint(x: starCenterPoint.x, y: starCenterPoint.y + starRadius)
            planetAnchor = CGPoint(x: planetCenterPoint.x, y: planetCenterPoint.y + planetRadius)
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
            let levelCount = game!.currentPack!.levels.count
            
            let levelVisibilityIndexShift: CGFloat = 2
            let levelStart = max(0, min(levelCount - 1, Int(floor(levelCurrent - levelVisibilityIndexShift))))
            let levelEnd = max(0, min(levelCount - 1, Int(ceil(levelCurrent + levelVisibilityIndexShift))))
            visibleLevelIndices = levelStart...levelEnd
        }
    }
    
    private func updateLiquidData() {
        guard 1...3 ~= state.levelToPackProgress, let particleRadius = game?.currentPack?.particleRadius else { return }
        
        var allPositions = [SIMD2<Float32>]()
        var allVelocities = [SIMD2<Float32>]()
        var allRadii = [Float32]()
        var allColors = [SIMD4<UInt8>]()
        
        if (state.levelToPackProgress < 3) {
            for (levelIndex, level) in visibleLevels.enumerated() {
                let levelNumber = visibleLevelIndices.lowerBound + levelIndex
                for chunk in level.initialChunks {
                    for particle in chunk.particles {
                        let center = particle.position
                        let point = convertPlanetChunkPosition(levelNumber, position: center)
                        let radius = self.convertPlanetRadius(particleRadius) ?? 0
                        
                        if isPointVisible(point, radius: radius) {
                            let color = particle.material.color
                            allPositions.append(SIMD2<Float32>(Float32(point.x), Float32(point.y)))
                            allVelocities.append(SIMD2<Float32>(Float32(0), Float32(0)))
                            allColors.append(color)
                            allRadii.append(Float(radius))
                        }
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
        
        terrainBody?.renderData = .init(particleRadius: Float(particleRadius),
                                        liquidFadeModifier: terrainBody?.liquidFadeModifier ?? 0,
                                        scale: 1,
                                        liquidCount: allPositions.count,
                                        liquidPositions: positions,
                                        liquidVelocities: velocities,
                                        liquidColors: colors)
    }
    
    private func updateStarsData() {
        for i in 0 ..< game!.levelManager.allLevelPacks.count {
            guard visibleLevelPackIndices ~= i else { continue }
            let star = stars[i]
            
            let point = self.convertStarPosition(i) ?? .zero
            let radius = self.convertStarRadius(star.pack.radius) ?? 0
            
            star.position = SIMD2<Float>(Float(point.x), Float(point.y))
            star.radius = Float(radius)
            
            let range = star.getMenuVisibleMissles(levelToPackProgress: state.levelToPackProgress,
                                                   levelIndex: state.currentLevelPagePosition,
                                                   misslesFired: star.state.currentMissleIndex)
            star.updateStarAppearance(levelToPackProgress: state.levelToPackProgress,
                                      levelIndex: state.currentLevelPagePosition,
                                      visibleMissleRange: range)
        }
    }
    
    private func updateCirclesData() {

    }
}

// Position calculations

extension MenuScene {
    private func convertStarPosition(_ index: Int) -> CGPoint? {
        var distToCenter: CGFloat = 0
        if state.levelToPackProgress > 2 {
            distToCenter = CGFloat(index) - state.currentPackPagePosition
        } else {
            distToCenter = CGFloat(index) - CGFloat(game!.state.packIndex)
        }
        let targetAngle = starCenterAngle + distToCenter * starAngleBetweenPositions
        let x = starAnchor.x - starRadius * cos(targetAngle)
        let y = starAnchor.y - starRadius * sin(targetAngle)
        return CGPoint(x: x, y: y)
    }

    private func convertStarRadius(_ radius: CGFloat) -> CGFloat? {
        radius * starRadiusScale
    }

    private func convertPlanetPosition(_ index: Int) -> CGPoint? {
        var distToCenter: CGFloat = 0
        if state.levelToPackProgress > 1, state.levelToPackProgress < 3 {
            distToCenter = CGFloat(index) - state.currentLevelPagePosition
        }
        let targetAngle = planetCenterAngle + distToCenter * planetAngleBetweenPositions
        let x = planetAnchor.x - planetRadius * cos(targetAngle)
        let y = planetAnchor.y - planetRadius * sin(targetAngle)
        return CGPoint(x: x, y: y)
    }

    private func convertPlanetRadius(_ radius: CGFloat) -> CGFloat? {
        radius * planetRadiusScale
    }

    private func convertPlanetChunkPosition(_ levelIndex: Int, position: CGPoint) -> CGPoint {
        let levelPosition = convertPlanetPosition(levelIndex) ?? .zero
        return CGPoint(x: levelPosition.x + position.x * planetRadiusScale, y: levelPosition.y + position.y * planetRadiusScale)
    }
}
