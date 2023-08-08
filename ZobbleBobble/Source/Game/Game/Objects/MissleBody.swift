//
//  MissleBody.swift
//  ZobbleBobble
//
//  Created by Rost on 02.08.2023.
//

import Foundation
import Levels

class MissleBody: LiquidBody {
    private let liquidFadeMultiplier: Float = 0
    
    var missleModel: ChunkModel
    weak var game: Game?
    weak var star: StarBody?
    
    var positions: [SIMD2<Float32>] = []
    var colors: [SIMD4<UInt8>] = []
    var velocities: [SIMD2<Float32>] = []
    
    private var idlePositions: [SIMD2<Float32>] = []
    private var readyPositions: [SIMD2<Float32>] = []
    
    init(missleModel: ChunkModel, star: StarBody, game: Game?) {
        self.missleModel = missleModel
        self.game = game
        self.star = star
        
        super.init()
        
        uniqueMaterials = Array(Set(missleModel.particles.map { $0.material }))
        
        updateTargetPositions()
        updateMisslePosition(0)
    }
    
    private func updateTargetPositions() {
        guard let star = star else { return }

        let starEdgeY = CGFloat(star.position.y - star.radius)
        let missleSpawnCenter = CGPoint(x: CGFloat(star.position.x),
                                        y: (starEdgeY - Settings.Camera.starMissleCenterOffset))
        
        let missleRadius = CGFloat(star.missleRadius)
        let idleAngleStart = CGFloat.pi
        let idleAngleEnd: CGFloat = 0
        
        var newIdle = [SIMD2<Float32>]()
        var newReady = [SIMD2<Float32>]()
        
        for i in 0 ..< missleModel.particles.count {
            let center = missleModel.particles[i].position
            
            let idleAngle = idleAngleStart + (idleAngleEnd - idleAngleStart) * CGFloat(i) / CGFloat(missleModel.particles.count - 1)
            let idleRadius = missleRadius
            
            let idleX = missleSpawnCenter.x + idleRadius * cos(idleAngle)
            let idleY = missleSpawnCenter.y + idleRadius * sin(idleAngle) + Settings.Camera.starMissleDeadZone
            
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
            let color = missleModel.particles[i].material.color
            var p = missleProgress
//            let random
//            if i % 3 == 0 {
//
//            }
            
            let idle = idlePositions[i]
            let ready = readyPositions[i]
            let current = SIMD2<Float32>(idle.x + (ready.x - idle.x) * Float(p),
                                         idle.y + (ready.y - idle.y) * Float(p))
            if i == 0 {
//                print("\(idle) \(ready)")
            }
            newVelocities.append(SIMD2<Float32>(0, 0))
            newColors.append(color)
            newPositions.append(current)
        }
        positions = newPositions
        colors = newColors
        velocities = newVelocities
        
        updateRenderData()
    }
    
    private func invalidateRenderData() {
        renderData = nil
    }
    
    private func updateRenderData() {
        guard let star = star, positions.count > 0 else {
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
        
        self.renderData = .init(particleRadius: Float(star.pack.particleRadius),
                                liquidFadeModifier: liquidFadeMultiplier,
                                scale: 1,
                                liquidCount: self.positions.count,
                                liquidPositions: positions,
                                liquidVelocities: velocities,
                                liquidColors: colors)
    }
}
