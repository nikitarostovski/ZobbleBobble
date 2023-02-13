//
//  Missle.swift
//  ZobbleBobble
//
//  Created by Rost on 13.02.2023.
//

import Foundation
import ZobbleCore

final class Missle {
    var missleModel: MissleModel
    weak var game: Game?
    weak var star: Star?
    
    var staticLiquidCount: Int?
    var staticLiquidPositions: UnsafeMutableRawPointer?
    var staticLiquidVelocities: UnsafeMutableRawPointer?
    var staticLiquidColors: UnsafeMutableRawPointer?
    
    var positions: [SIMD2<Float32>] = []
    var colors: [SIMD4<UInt8>] = []
    var velocities: [SIMD2<Float32>] = []
    
    private var idlePositions: [SIMD2<Float32>] = []
    private var readyPositions: [SIMD2<Float32>] = []
    
    init(missleModel: MissleModel, star: Star, game: Game?) {
        self.missleModel = missleModel
        self.game = game
        self.star = star
        
        updateTargetPositions()
        updateMisslePosition(0)
    }
    
    private func updateTargetPositions() {
        guard let star = star else { return }
        let missleSpawnCenter = CGPoint(x: CGFloat(star.position.x),
                                        y: CGFloat(star.position.y) - CGFloat(star.radius) - Settings.levelMissleCenterOffset)
        
        let missleRadius = missleModel.shape.boundingRadius
        let idleAngleStart = CGFloat.pi
        let idleAngleEnd: CGFloat = 0
        
        var newIdle = [SIMD2<Float32>]()
        var newReady = [SIMD2<Float32>]()
        
        for i in 0 ..< missleModel.shape.particleCenters.count {
            let center = missleModel.shape.particleCenters[i]
            
            let idleAngle = idleAngleStart + (idleAngleEnd - idleAngleStart) * CGFloat(i) / CGFloat(missleModel.shape.particleCenters.count - 1)
            let idleRadius = missleRadius * 5
            
            let idleX = missleSpawnCenter.x + idleRadius * cos(idleAngle)
            let idleY = missleSpawnCenter.y + idleRadius * sin(idleAngle)
            
            let idleCenter = SIMD2<Float32>(x: Float32(idleX),
                                            y: Float32(idleY))
            let readyCenter = SIMD2<Float32>(x: Float32(center.x + missleSpawnCenter.x),
                                             y: Float32(center.y + missleSpawnCenter.y))
            newIdle.append(idleCenter)
            newReady.append(readyCenter)
        }
        
        readyPositions = newReady
        idlePositions = newIdle
    }
    
    /// Updates particle positions
    /// - Parameter missleProgress: 0 is at the edge of the star, 1 is redy to fire
    func updateMisslePosition(_ missleProgress: CGFloat) {
        invalidateRenderData()
        guard !readyPositions.isEmpty, !readyPositions.isEmpty, idlePositions.count == readyPositions.count else { return }
        
        var newPositions: [SIMD2<Float32>] = []
        var newColors: [SIMD4<UInt8>] = []
        var newVelocities: [SIMD2<Float32>] = []
        
        for i in 0..<readyPositions.count {
            let idle = idlePositions[i]
            let ready = readyPositions[i]
            
            let current = SIMD2<Float32>(idle.x + (ready.x - idle.x) * Float(missleProgress),
                                         idle.y + (ready.y - idle.y) * Float(missleProgress))
            
            newVelocities.append(SIMD2<Float32>(0, 0))
            newColors.append(missleModel.material.color)
            newPositions.append(current)
        }
        self.positions = newPositions
        self.colors = newColors
        self.velocities = newVelocities
        self.staticLiquidCount = newPositions.count
        updateRenderData()
    }
    
    private func invalidateRenderData() {
        self.staticLiquidPositions = nil
        self.staticLiquidColors = nil
        self.staticLiquidVelocities = nil
        self.staticLiquidCount = nil
    }
    
    private func updateRenderData() {
        guard let staticLiquidCount = staticLiquidCount, staticLiquidCount > 0 else {
            invalidateRenderData()
            return
        }
        
        let positions = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * self.positions.count,
                                                         alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        positions.copyMemory(from: &self.positions,
                             byteCount: MemoryLayout<SIMD2<Float32>>.stride * self.positions.count)
        
        let velocities = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * self.velocities.count,
                                                          alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        velocities.copyMemory(from: &self.velocities,
                              byteCount: MemoryLayout<SIMD2<Float32>>.stride * self.velocities.count)
        
        let colors = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * self.colors.count,
                                                      alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        colors.copyMemory(from: &self.colors,
                          byteCount: MemoryLayout<SIMD4<UInt8>>.stride * self.colors.count)
        
        self.staticLiquidPositions = positions
        self.staticLiquidColors = colors
        self.staticLiquidVelocities = velocities
        self.staticLiquidCount = self.positions.count

    }
}
