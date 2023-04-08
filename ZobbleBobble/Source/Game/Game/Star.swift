//
//  Star.swift
//  ZobbleBobble
//
//  Created by Rost on 29.01.2023.
//

import Foundation
import ZobbleCore

struct StarMaterialData {
    let color: SIMD4<UInt8>
    let position: SIMD2<Float>
}

struct StarState {
    var visibleMaterials = [StarMaterialData]()
    var currentLevelIndex: CGFloat = 0
    var visibleMissleRange: ClosedRange<CGFloat> = 0...0
}

final class Star {
    weak var game: Game?
    
    var pack: PackModel
    var state: StarState
    var number: Int
    
    private let initialMaterials: [StarMaterialData]
    
//    private(set) var missleIndicesToSkip: CGFloat = 0
//
//    /// 0 is showing only current level missles, 1 is showing all level missles
//    private(set) var clipMisslesProgress: CGFloat = 0
//
////    private(set) var renderCenterVerticalOffset: CGFloat = 0
    
    var position: SIMD2<Float>
    var renderCenter: SIMD2<Float>
    var missleCenter: SIMD2<Float>
    
    var radius: Float
    var missleRadius: Float
    var mainColor: SIMD4<UInt8>
    
    var positionPointer: UnsafeMutableRawPointer!
    var renderCenterPointer: UnsafeMutableRawPointer!
    var missleCenterPointer: UnsafeMutableRawPointer!
    var radiusPointer: UnsafeMutableRawPointer!
    var missleRadiusPointer: UnsafeMutableRawPointer!
    var materialsPointer: UnsafeMutableRawPointer!
    
    init(game: Game, number: Int) {
        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
        self.pack = pack
        self.game = game
        self.number = number
        self.state = StarState()
        self.position = SIMD2<Float>(0, 0)
        self.renderCenter = SIMD2<Float>(0, 0)
        self.missleCenter = SIMD2<Float>(0, 0)
        self.radius = Float(pack.radius)
        self.mainColor = SIMD4<UInt8>(255, 255, 255, 255)
        self.missleRadius = 0
        
        var materials = [StarMaterialData]()
        for (i, l) in pack.levels.enumerated() {
            for (j, m) in l.missles.enumerated() {
                let number = CGFloat(i) + CGFloat(j) / CGFloat(l.missles.count)
                let next = number + CGFloat(1) / CGFloat(l.missles.count)
                let material = StarMaterialData(color: m.material.color, position: SIMD2(Float(number), Float(next)))
                materials.append(material)
            }
        }
        self.initialMaterials = materials
        updateRenderData()
    }
    
    func getMenuVisibleMissles(levelToPackProgress: CGFloat, levelIndex: CGFloat) -> ClosedRange<CGFloat> {
        let packsLo: CGFloat = 0
        let packsHi: CGFloat = CGFloat(pack.levels.count)
        
        let levelsLo = levelIndex
        let levelsHi = levelIndex + 1
        
        let levelLo: CGFloat = levelIndex
        let levelHi: CGFloat = levelIndex + 1
        
        var lo: CGFloat = 0
        var hi: CGFloat = 0
        if Settings.levelCameraScale...Settings.levelsMenuCameraScale ~= levelToPackProgress {
            // level to levels menu
            let p = levelToPackProgress - Settings.levelCameraScale
            lo = levelLo + (levelsLo - levelLo) * p
            hi = levelHi + (levelsHi - levelHi) * p
        } else if Settings.levelsMenuCameraScale...Settings.packsMenuCameraScale ~= levelToPackProgress {
            // levels to packs menu
            let p = levelToPackProgress - Settings.levelsMenuCameraScale
            lo = levelsLo + (packsLo - levelsLo) * p
            hi = levelsHi + (packsHi - levelsHi) * p
        }
        return min(lo, hi)...max(lo, hi)
    }
    
    func getWorldVisibleMissles(levelIndex: Int, misslesFired: CGFloat) -> ClosedRange<CGFloat> {
        guard 0..<pack.levels.count ~= levelIndex else { return 0...0 }
        let level = pack.levels[levelIndex]
        let missleWeight = CGFloat(1) / CGFloat(level.missles.count)
        
        let lo = CGFloat(levelIndex) + misslesFired * missleWeight
        let hi = CGFloat(Int(levelIndex)) + 1
        
        guard lo <= hi else { return 0...0 }
        
        return lo...hi
    }
    
    func getMissleRadius(levelToPackProgress: CGFloat, missleIndex: CGFloat) -> Float {
        let activeLevelIndex = Int(missleIndex)
        guard 0..<pack.levels.count ~= activeLevelIndex else { return 0 }
        
        let level = pack.levels[activeLevelIndex]
        
        let missleProgress = missleIndex - CGFloat(activeLevelIndex)
        
        let activeMissleIndexFloating = missleProgress * CGFloat(level.missles.count) - 1
        let activeMissleIndex = Int(activeMissleIndexFloating)
        
        var currentRadius: CGFloat = 0
        var nextRadius: CGFloat = 0
        
        if 0..<level.missles.count ~= activeMissleIndex {
            let currentMissle = level.missles[activeMissleIndex]
            currentRadius = currentMissle.shape.boundingRadius
        }
        
        if 0..<(level.missles.count - 1) ~= activeMissleIndex {
            let nextMissle = level.missles[activeMissleIndex + 1]
            nextRadius = nextMissle.shape.boundingRadius
        }
        
        let scaleProgress = levelToPackProgress - Settings.levelCameraScale
        
        let mp = activeMissleIndexFloating - CGFloat(activeMissleIndex)
        
        let levelsMissleRadius: CGFloat = 0
        let levelMissleRadius: CGFloat = currentRadius + (nextRadius - currentRadius) * mp + Settings.starMissleDeadZone
        let missleRadius = levelMissleRadius + (levelsMissleRadius - levelMissleRadius) * scaleProgress
        
        return Float(missleRadius)
    }
    
    func getRenderCenter(levelToPackProgress: CGFloat) -> SIMD2<Float> {
        let missleScale = 1 - max(0, min(1, levelToPackProgress - Settings.levelCameraScale))
        let renderCenterVerticalOffset = missleScale * (CGFloat(radius) + Settings.starMissleCenterOffset)
        return SIMD2<Float32>(position.x, position.y - Float(renderCenterVerticalOffset))
    }
    
    func getMissleCenter() -> SIMD2<Float> {
        SIMD2<Float32>(position.x, position.y - radius - Float(Settings.starMissleCenterOffset))
    }
    
    func updateStarAppearance(levelToPackProgress: CGFloat, levelIndex: CGFloat, visibleMissleRange: ClosedRange<CGFloat>) {
//        guard visibleMissleRange.upperBound != visibleMissleRange.lowerBound else { return }
        
        self.state.visibleMissleRange = visibleMissleRange
        self.state.currentLevelIndex = levelIndex
        
        self.missleRadius = getMissleRadius(levelToPackProgress: levelToPackProgress, missleIndex: visibleMissleRange.lowerBound)
        self.renderCenter = getRenderCenter(levelToPackProgress: levelToPackProgress)
        self.missleCenter = getMissleCenter()
        
        let materialScale: CGFloat = min(max(1, Settings.packsMenuCameraScale - levelToPackProgress), Settings.planetMaterialsUpscaleInGame)
        
        var visibleCorrectedMaterials: [StarMaterialData] = initialMaterials.enumerated().compactMap { i, m in
            let start = CGFloat(m.position.x)
            let end = CGFloat(m.position.y)
            
            let rangeDist = visibleMissleRange.upperBound - visibleMissleRange.lowerBound
            
            let convertedStart = (start - visibleMissleRange.lowerBound) / rangeDist * materialScale
            let convertedEnd = (end - visibleMissleRange.lowerBound) / rangeDist * materialScale
            
            let visibilityRange: ClosedRange<CGFloat> = 0...materialScale
            
            if visibilityRange.contains(convertedStart) || visibilityRange.contains(convertedEnd) {
                return StarMaterialData(color: m.color, position: SIMD2(Float(convertedStart), Float(convertedEnd)))
            }
            
            return nil
        }
        
        let rootMaterial = StarMaterialData(color: self.mainColor, position: SIMD2<Float>(0, 1))
        visibleCorrectedMaterials.append(rootMaterial)
        
        self.state.visibleMaterials = visibleCorrectedMaterials
        
        updateRenderData()
    }
    
//    func updateVisibleMissles(levelToPackProgress: CGFloat, missleIndicesToSkip: CGFloat? = nil, clipMisslesProgress: CGFloat? = nil, missleRadius: Float? = nil) {
//
//        self.missleRadius = missleRadius ?? self.missleRadius
//        self.missleIndicesToSkip = missleIndicesToSkip ?? self.missleIndicesToSkip
//        self.clipMisslesProgress = clipMisslesProgress ?? self.clipMisslesProgress
//
//        let missleScale = 1 - max(0, min(1, levelToPackProgress - 1))
//        self.renderCenterVerticalOffset = missleScale * (CGFloat(self.radius) + Settings.starMissleCenterOffset)
//
//        let missleRadius = self.missleRadius
//        let missleIndicesToSkip = self.missleIndicesToSkip
//        let renderCenterVerticalOffset = self.renderCenterVerticalOffset
//
//        guard let game = game else {
//            return
//        }
//
////        print(missleRadius)
//        let p = levelToPackProgress - 2
//
////        let notchOffset: Float = (missleRadius - Float(Settings.starMissleCenterOffset)) / radius
////        let starEffectiveSize: Float = 1 - notchOffset
////        print(notchOffset)
//
//        let levelIndex = game.state.levelIndex
//        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
//
//        var materialsData = [StarMaterialData]()
//
//        var materialOffset = 0
//        var previousMaterialPositionEnd: Float = 0
//        for (i, level) in pack.levels.enumerated() {
//            let missleIndicesToSkip = i == levelIndex ? missleIndicesToSkip : 0
//
//            for (j, missle) in level.missles.enumerated() {
//                var materialLevelScale = CGFloat(i - levelIndex)
//                materialLevelScale += (CGFloat(j + 1) - missleIndicesToSkip) / CGFloat(level.missles.count)
//
//                let totalIndex = CGFloat(j + materialOffset)
//                let materialMenuScale = (totalIndex + 1) / CGFloat(pack.missleCount)
//
//                let materialScale = materialLevelScale + (materialMenuScale - materialLevelScale) * p
//
//                guard materialScale != CGFloat(previousMaterialPositionEnd) else { continue }
//
//                let bounds: ClosedRange<Float> = 0 ... 1
//
//                if bounds ~= Float(materialScale) || bounds ~= previousMaterialPositionEnd, materialScale > CGFloat(previousMaterialPositionEnd) {
//                    let pos = SIMD2<Float>(Float(previousMaterialPositionEnd), Float(materialScale))
//                    let materialData = StarMaterialData(color: missle.material.color,
//                                                        position: pos)
//                    materialsData.append(materialData)
//                }
//
//                if j != level.missles.count - 1 {
//                    previousMaterialPositionEnd = Float(materialScale)
//                } else {
//                    previousMaterialPositionEnd = -1
//                }
//            }
//            materialOffset += level.missles.count
//        }
//        let rootMaterial = StarMaterialData(color: self.mainColor, position: SIMD2<Float>(0, 1))
//        materialsData.append(rootMaterial)
//
//        self.state.visibleMaterials = materialsData
//        self.renderCenter = SIMD2<Float32>(self.position.x, self.position.y - Float(renderCenterVerticalOffset))
//        self.missleCenter = SIMD2<Float32>(self.position.x, self.position.y - self.radius - Float(Settings.starMissleCenterOffset))
//
//        updateRenderData()
//    }
    
    private func updateRenderData() {
        self.positionPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        self.positionPointer.copyMemory(from: &self.position, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        self.renderCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                    alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        self.renderCenterPointer.copyMemory(from: &self.renderCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        self.missleCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                    alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        self.missleCenterPointer.copyMemory(from: &self.missleCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        self.radiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                alignment: MemoryLayout<Float32>.alignment)
        self.radiusPointer.copyMemory(from: &self.radius, byteCount: MemoryLayout<Float32>.stride)
        
        self.missleRadiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                alignment: MemoryLayout<Float32>.alignment)
        self.missleRadiusPointer.copyMemory(from: &self.missleRadius, byteCount: MemoryLayout<Float32>.stride)
        
        self.materialsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<StarMaterialData>.stride * state.visibleMaterials.count,
                                                                alignment: MemoryLayout<StarMaterialData>.alignment)
        self.materialsPointer.copyMemory(from: self.state.visibleMaterials, byteCount: MemoryLayout<StarMaterialData>.stride * state.visibleMaterials.count)
    }
}
