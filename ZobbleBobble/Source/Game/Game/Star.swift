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
    var currentMissleIndex: CGFloat = 0
    var visibleMissleRange: ClosedRange<CGFloat> = 0...0
}

final class Star {
    weak var game: Game?
    
    var pack: PackModel
    var state: StarState
    var number: Int
    
    private let initialMaterials: [StarMaterialData]
    
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
                let next = number + CGFloat(1) / CGFloat(l.missles.count)// - 0.01//CGFloat.leastNonzeroMagnitude
                let material = StarMaterialData(color: m.material.color, position: SIMD2(Float(number), Float(next)))
                materials.append(material)
            }
        }
        self.initialMaterials = materials
        updateRenderData()
    }
    
    func getMenuVisibleMissles(levelToPackProgress: CGFloat, levelIndex: CGFloat, misslesFired: CGFloat) -> ClosedRange<CGFloat> {
        let level = pack.levels[Int(levelIndex)]
        let missleWeight = CGFloat(1) / CGFloat(level.missles.count)
        
        let packsLo: CGFloat = 0
        let packsHi: CGFloat = CGFloat(pack.levels.count)
        
        let levelsLo = levelIndex
        let levelsHi = levelIndex + 1
        
        let levelLo: CGFloat = levelIndex + misslesFired * missleWeight
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
    
    func getMissleRadius(levelToPackProgress: CGFloat, levelIndex: Int, missleIndexFloating: CGFloat) -> Float {
        let missleIndexFloating = missleIndexFloating - 1
        let missleIndex = max(0, Int(missleIndexFloating))
        let level = pack.levels[levelIndex]
        
        var currentRadius: CGFloat = 0
        var nextRadius: CGFloat = 0
        
        if 0..<level.missles.count ~= missleIndex {
            let currentMissle = level.missles[missleIndex]
            currentRadius = currentMissle.shape.boundingRadius
        }
        
        if 0..<(level.missles.count - 1) ~= missleIndex {
            let nextMissle = level.missles[missleIndex + 1]
            nextRadius = nextMissle.shape.boundingRadius
        }
        
        let scaleProgress = levelToPackProgress - Settings.levelCameraScale
        let mp = missleIndexFloating - CGFloat(missleIndex)
        
        let levelsMissleRadius: CGFloat = 0
        let levelMissleRadius: CGFloat = currentRadius + (nextRadius - currentRadius) * mp + Settings.starMissleDeadZone
        let missleRadius = levelMissleRadius + (levelsMissleRadius - levelMissleRadius) * scaleProgress
        
        return Float(max(0, missleRadius))
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
        self.state.visibleMissleRange = visibleMissleRange
        self.state.currentLevelIndex = levelIndex
        
        let level = pack.levels[Int(levelIndex)]
        let missleIndex = CGFloat(level.missles.count) * (visibleMissleRange.lowerBound - CGFloat(Int(levelIndex)))
        self.missleRadius = getMissleRadius(levelToPackProgress: levelToPackProgress,
                                            levelIndex: Int(levelIndex),
                                            missleIndexFloating: missleIndex)
        
        self.renderCenter = getRenderCenter(levelToPackProgress: levelToPackProgress)
        self.missleCenter = getMissleCenter()
        
        let p = max(0, min(1, levelToPackProgress - Settings.levelsMenuCameraScale))
        let addScale = 1 + (visibleMissleRange.upperBound - visibleMissleRange.lowerBound - 1) * p // for packs menu
        let materialScale = min(max(1, Settings.packsMenuCameraScale - levelToPackProgress), Settings.planetMaterialsUpscaleInGame)
        
        let visibilityRange: Range<CGFloat> = CGFloat.leastNonzeroMagnitude..<materialScale
        let colorMixStrength: CGFloat = 1 - max(0, min(1, levelToPackProgress - Settings.levelCameraScale))
        
        var visibleCorrectedMaterials: [StarMaterialData] = initialMaterials.enumerated().compactMap { _, m in
            let start = CGFloat(m.position.x)
            let end = CGFloat(m.position.y)
            
            let isInCurrentLevel = Int(start) == Int(levelIndex)
            let color = isInCurrentLevel ? m.color : m.color.mix(with: mainColor, progress: colorMixStrength)
            
            let convertedStart = (start - visibleMissleRange.lowerBound) * materialScale / addScale
            let convertedEnd = (end - visibleMissleRange.lowerBound) * materialScale / addScale
            
            if visibilityRange.contains(convertedStart) || visibilityRange.contains(convertedEnd) {
                return StarMaterialData(color: color, position: SIMD2(Float(convertedStart), Float(convertedEnd)))
            }
            return nil
        }
        let rootMissleColor = visibleCorrectedMaterials.first?.color ?? self.mainColor
        let rootPosition = SIMD2<Float>(Float(visibilityRange.lowerBound), Float(visibilityRange.upperBound))
        let rootMaterial = StarMaterialData(color: rootMissleColor, position: rootPosition)
        visibleCorrectedMaterials.append(rootMaterial)
        
        self.state.visibleMaterials = visibleCorrectedMaterials
        updateRenderData()
    }
    
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
