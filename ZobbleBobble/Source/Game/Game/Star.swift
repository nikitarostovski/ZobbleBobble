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
}

final class Star {
    weak var game: Game?
    
    var state: StarState
    var number: Int
    var missleIndicesToSkip: CGFloat = 0
    
    /// 0 is showing only current level missles, 1 is showing all level missles
    var clipMisslesProgress: CGFloat = 0
    
    var position: SIMD2<Float>
    var radius: Float
    var mainColor: SIMD4<UInt8>
    var missleRadius: Float
    
    var positionPointer: UnsafeMutableRawPointer!
    var radiusPointer: UnsafeMutableRawPointer!
    var missleRadiusPointer: UnsafeMutableRawPointer!
    var mainColorPointer: UnsafeMutableRawPointer!
    var materialsPointer: UnsafeMutableRawPointer!
    
    
    init(game: Game, number: Int) {
        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
        
        self.game = game
        self.number = number
        self.state = StarState()
        self.position = SIMD2<Float>(Float(0), Float(0))
        self.radius = Float(pack.radius)
        self.mainColor = SIMD4<UInt8>(255, 255, 255, 255)
        self.missleRadius = 0
        
        updateVisibleMissles(levelToPackProgress: Menu.levelsMenuCameraScale)
    }
    
    func updateVisibleMissles(levelToPackProgress: CGFloat) {
        guard let game = game else { return }
        
        let levelIndex = game.state.levelIndex
        let pack = game.levelManager.allLevelPacks[game.state.packIndex]
        
        var materialsData = [StarMaterialData]()
        
//        if levelToPackProgress <= 2 {
//            // 0 == level, 1 == level selection
//            let p = levelToPackProgress - 1
//
//        } else {
//            // 0 == level selection, 1 == pack selection
//            let p = levelToPackProgress - 2
//
//        }
        
        let p = min(1, levelToPackProgress - 1)
        
        var materialOffset = 0
        var previousMaterialPositionEnd: Float = 0
        for (i, level) in pack.levels.enumerated() {
            let missleIndicesToSkip = i == levelIndex ? missleIndicesToSkip : 0
            
            for (j, missle) in level.missles.enumerated() {
                var materialLevelScale = CGFloat(i - levelIndex)
                materialLevelScale += (CGFloat(j + 1) - missleIndicesToSkip) / CGFloat(level.missles.count)
                
                let totalIndex = CGFloat(j + materialOffset)
                let materialMenuScale = (totalIndex + 1) / CGFloat(pack.missleCount)
                
                let materialScale = materialLevelScale + (materialMenuScale - materialLevelScale) * p
                
                guard materialScale != CGFloat(previousMaterialPositionEnd) else { continue }
                
                if 0...1 ~= materialScale || 0...1 ~= previousMaterialPositionEnd, materialScale > CGFloat(previousMaterialPositionEnd) {
                    let pos = SIMD2<Float>(Float(1 - materialScale), 1 - previousMaterialPositionEnd)
                    let materialData = StarMaterialData(color: missle.material.color,
                                                        position: pos)
                    materialsData.append(materialData)
                }
                
                if j != level.missles.count - 1 {
                    previousMaterialPositionEnd = Float(materialScale)
                } else {
                    previousMaterialPositionEnd = -1
                }
            }
            materialOffset += level.missles.count
        }
        
        self.state.visibleMaterials = materialsData
        
//        let missleIndex = missleIndicesToSkip % floor(missleIndicesToSkip)
//        let missle = game.levelManager.allLevelPacks[game.state.packIndex].levels[game.state.levelIndex].missles[missleIndex]
//        miss
        
        
        
        updateRenderData()
    }
    
    private func updateRenderData() {
        self.positionPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        self.positionPointer.copyMemory(from: &self.position, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        self.radiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                alignment: MemoryLayout<Float32>.alignment)
        self.radiusPointer.copyMemory(from: &self.radius, byteCount: MemoryLayout<Float32>.stride)
        
        self.missleRadiusPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float32>.stride,
                                                                alignment: MemoryLayout<Float32>.alignment)
        self.missleRadiusPointer.copyMemory(from: &self.missleRadius, byteCount: MemoryLayout<Float32>.stride)
        
        self.mainColorPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride,
                                                                alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        self.mainColorPointer.copyMemory(from: &self.mainColor, byteCount: MemoryLayout<SIMD4<UInt8>>.stride)
        
        self.materialsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<StarMaterialData>.stride * state.visibleMaterials.count,
                                                                alignment: MemoryLayout<StarMaterialData>.alignment)
        self.materialsPointer.copyMemory(from: self.state.visibleMaterials, byteCount: MemoryLayout<StarMaterialData>.stride * state.visibleMaterials.count)
    }
}
