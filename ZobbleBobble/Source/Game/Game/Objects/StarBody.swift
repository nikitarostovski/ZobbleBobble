//
//  StarBody.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import Levels

struct StarMaterialData {
    let color: SIMD4<UInt8>
    let position: SIMD2<Float>
}

class StarBody: Body {
    struct State {
        var visibleMaterials = [StarMaterialData]()
        var currentLevelIndex: CGFloat = 0
        var currentMissleIndex: CGFloat = 0
        var visibleMissleRange: ClosedRange<CGFloat> = 0...0
    }
    
    var renderData: StarRenderData?
    
    weak var game: Game?
    
    let pack: PackModel
    var state = State()
    
    private let initialMaterials: [StarMaterialData]
    
    var position = SIMD2<Float>(0, 0)
    var radius: Float
    var missleRadius: Float
    var mainColor: SIMD4<UInt8>
    
    private(set) var renderCenter = SIMD2<Float>(0, 0)
    private(set) var missleCenter = SIMD2<Float>(0, 0)
    
    var uniqueMaterials: [MaterialType] { [] }
    
    init(game: Game, pack: PackModel) {
        self.pack = pack
        self.game = game
        
        self.radius = Float(pack.radius)
        self.mainColor = Colors.Stars.mainColor
        self.missleRadius = 0
        
        var materials = [StarMaterialData]()
        for (i, l) in pack.levels.enumerated() {
            for (j, m) in l.missleChunks.enumerated() {
                let number = CGFloat(i) + CGFloat(j) / CGFloat(l.missleChunks.count)
                let next = number + CGFloat(1) / CGFloat(l.missleChunks.count)// - 0.01//CGFloat.leastNonzeroMagnitude
                var color = m.particles.first?.material.color ?? SIMD4<UInt8>(repeating: 0)//m.material.color
                color.w = 255;
                let material = StarMaterialData(color: color, position: SIMD2(Float(number), Float(next)))
                materials.append(material)
            }
        }
        self.initialMaterials = materials
        createRenderData()
        updateRenderData()
    }
    
    func getMenuVisibleMissles(levelToPackProgress: CGFloat, levelIndex: CGFloat, misslesFired: CGFloat) -> ClosedRange<CGFloat> {
        let level = pack.levels[Int(levelIndex)]
        let missleWeight = CGFloat(1) / CGFloat(level.missleChunks.count)
        
        let packsLo: CGFloat = 0
        let packsHi: CGFloat = CGFloat(pack.levels.count)
        
        let levelsLo = levelIndex
        let levelsHi = levelIndex + 1
        
        let levelLo: CGFloat = levelIndex + misslesFired * missleWeight
        let levelHi: CGFloat = levelIndex + 1
        
        var lo: CGFloat = 0
        var hi: CGFloat = 0
        if Settings.Camera.levelCameraScale...Settings.Camera.levelsMenuCameraScale ~= levelToPackProgress {
            // level to levels menu
            let p = levelToPackProgress - Settings.Camera.levelCameraScale
            lo = levelLo + (levelsLo - levelLo) * p
            hi = levelHi + (levelsHi - levelHi) * p
        } else if Settings.Camera.levelsMenuCameraScale...Settings.Camera.packsMenuCameraScale ~= levelToPackProgress {
            // levels to packs menu
            let p = levelToPackProgress - Settings.Camera.levelsMenuCameraScale
            lo = levelsLo + (packsLo - levelsLo) * p
            hi = levelsHi + (packsHi - levelsHi) * p
        }
        return min(lo, hi)...max(lo, hi)
    }
    
    func getWorldVisibleMissles(levelIndex: Int, misslesFired: CGFloat) -> ClosedRange<CGFloat> {
        guard 0..<pack.levels.count ~= levelIndex else { return 0...0 }
        let level = pack.levels[levelIndex]
        let missleWeight = CGFloat(1) / CGFloat(level.missleChunks.count)
        
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
        
        if 0..<level.missleChunks.count ~= missleIndex {
            let currentMissle = level.missleChunks[missleIndex]
            currentRadius = currentMissle.boundingRadius
        }
        
        if 0..<(level.missleChunks.count - 1) ~= missleIndex {
            let nextMissle = level.missleChunks[missleIndex + 1]
            nextRadius = nextMissle.boundingRadius
        }
        
        let scaleProgress = levelToPackProgress - Settings.Camera.levelCameraScale
        let mp = missleIndexFloating - CGFloat(missleIndex)
        
        let levelsMissleRadius: CGFloat = 0
        let levelMissleRadius: CGFloat = currentRadius + (nextRadius - currentRadius) * mp + Settings.Camera.starMissleDeadZone
        let missleRadius = levelMissleRadius + (levelsMissleRadius - levelMissleRadius) * scaleProgress
        
        return Float(max(0, missleRadius))
    }
    
    func getRenderCenter(levelToPackProgress: CGFloat) -> SIMD2<Float> {
        let missleScale = 1 - max(0, min(1, levelToPackProgress - Settings.Camera.levelCameraScale))
        let renderCenterVerticalOffset = missleScale * (CGFloat(radius) + Settings.Camera.starMissleCenterOffset)
        return SIMD2<Float32>(position.x, position.y - Float(renderCenterVerticalOffset))
    }
    
    func getMissleCenter() -> SIMD2<Float> {
        SIMD2<Float32>(position.x, position.y - radius - Float(Settings.Camera.starMissleCenterOffset))
    }
    
    func updateStarAppearance(levelToPackProgress: CGFloat, levelIndex: CGFloat, visibleMissleRange: ClosedRange<CGFloat>) {
        self.state.visibleMissleRange = visibleMissleRange
        self.state.currentLevelIndex = levelIndex
        
        let level = pack.levels[Int(levelIndex)]
        let missleIndex = CGFloat(level.missleChunks.count) * (visibleMissleRange.lowerBound - CGFloat(Int(levelIndex)))
        self.missleRadius = getMissleRadius(levelToPackProgress: levelToPackProgress,
                                            levelIndex: Int(levelIndex),
                                            missleIndexFloating: missleIndex)
        
        self.renderCenter = getRenderCenter(levelToPackProgress: levelToPackProgress)
        self.missleCenter = getMissleCenter()
        
        let p = max(0, min(1, levelToPackProgress - Settings.Camera.levelsMenuCameraScale))
        let addScale = 1 + (visibleMissleRange.upperBound - visibleMissleRange.lowerBound - 1) * p // for packs menu
        let materialScale = min(max(1, Settings.Camera.packsMenuCameraScale - levelToPackProgress), Settings.Camera.planetMaterialsUpscaleInGame)
        
        let visibilityRange: Range<CGFloat> = CGFloat.leastNonzeroMagnitude..<materialScale
        let colorMixStrength: CGFloat = 1 - max(0, min(1, levelToPackProgress - Settings.Camera.levelCameraScale))
        
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
        var rootColor = visibleCorrectedMaterials.first?.color ?? self.mainColor
        if levelToPackProgress == Settings.Camera.levelCameraScale {
            rootColor = mainColor
        }
        let rootPosition = SIMD2<Float>(Float(visibilityRange.lowerBound), Float(visibilityRange.upperBound))
        let rootMaterial = StarMaterialData(color: rootColor, position: rootPosition)
        visibleCorrectedMaterials.append(rootMaterial)
        
        self.state.visibleMaterials = visibleCorrectedMaterials
        updateRenderData()
    }
    
    private func createRenderData() {
        let positionPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                               alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let renderCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                   alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let missleCenterPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                   alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let radiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                             alignment: MemoryLayout<Float32>.alignment)
        let missleRadiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                   alignment: MemoryLayout<Float32>.alignment)
        self.renderData = .init(positionPointer: positionPointer,
                                renderCenterPointer: renderCenterPointer,
                                missleCenterPointer: missleCenterPointer,
                                radiusPointer: radiusPointer,
                                missleRadiusPointer: missleRadiusPointer,
                                materialsPointer: materialsPointer,
                                materialCount: materialCount)
    }
    
    private func updateRenderData() {
        guard let renderData = renderData else { return }
        
        renderData.positionPointer.copyMemory(from: &self.position, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.renderCenterPointer.copyMemory(from: &self.renderCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.missleCenterPointer.copyMemory(from: &self.missleCenter, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        renderData.radiusPointer.copyMemory(from: &self.radius, byteCount: MemoryLayout<Float32>.stride)
        
        renderData.missleRadiusPointer.copyMemory(from: &self.missleRadius, byteCount: MemoryLayout<Float32>.stride)
        
        self.renderData?.materialsPointer = materialsPointer
        self.renderData?.materialCount = materialCount
    }
    
    private var materialCount: Int {
        state.visibleMaterials.count
    }
    
    private var materialsPointer: UnsafeMutableRawPointer {
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<StarMaterialData>.stride * materialCount,
                                                       alignment: MemoryLayout<StarMaterialData>.alignment)
        pointer.copyMemory(from: self.state.visibleMaterials, byteCount: MemoryLayout<StarMaterialData>.stride * materialCount)
        return pointer
    }
}
