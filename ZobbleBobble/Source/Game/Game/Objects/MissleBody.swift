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
    
    /// per-particle positions when missle starts to appear
    private var idlePositions: [SIMD2<Float32>] = []
    /// per-particle positions when missle is ready to fire
    private var readyPositions: [SIMD2<Float32>] = []
    
    private var speedModifiers: [CGFloat] = []
    
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
        
        let starRadius = CGFloat(star.radius)
        let missleRadius = CGFloat(star.missleRadius) + Settings.Camera.missleRadiusShiftInsideStar
        
        let starCenter = CGPoint(x: CGFloat(star.position.x),
                                 y: CGFloat(star.position.y))
        let missleCenter = CGPoint(x: starCenter.x,
                                   y: starCenter.y - starRadius - Settings.Camera.starMissleCenterOffset)
        
        let d = missleCenter.distance(to: starCenter)
        
        // angle from missle center to star edge (intersection point)
        let intersectionAngle = CGFloat.circleIntersectionAngle(r1: missleRadius, r2: starRadius, d: d)
        let angleShift = missleCenter.angle(to: starCenter).radians
        
        // fill idle
        let idleAngleStart = intersectionAngle - Settings.Camera.missleAngleShiftInsideStar
        let idleAngleEnd = -intersectionAngle + Settings.Camera.missleAngleShiftInsideStar
        
        let angleStep = (idleAngleEnd - idleAngleStart) / CGFloat(missleModel.particles.count - 1)
        
        idlePositions = missleModel.particles.indices.map { i in
            let angle = angleShift + idleAngleStart + CGFloat(i) * angleStep
            
            let idleX = missleCenter.x + missleRadius * cos(angle)
            let idleY = missleCenter.y + missleRadius * sin(angle)
            
            return SIMD2<Float32>(x: Float32(idleX),
                                  y: Float32(idleY))
        }.shuffled()
        
        // fill ready positions
        readyPositions = missleModel.particles.map { particle in
            SIMD2<Float32>(x: Float32(particle.position.x + missleCenter.x),
                           y: Float32(particle.position.y + missleCenter.y))
        }
        
        // fill speed
        speedModifiers = missleModel.particles.map { particle in
            let verticalPosition = 1 - (particle.position.y / missleModel.boundingRadius + 1) / 2
            return 1 + verticalPosition * (Settings.Camera.missleParticleMaxSpeedModifier - 1)
        }
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
            let speedModifier = speedModifiers[i]
            let idle = idlePositions[i]
            let ready = readyPositions[i]
            
            let p = max(0, min(1, missleProgress * speedModifier))
            let current = SIMD2<Float32>(idle.x + (ready.x - idle.x) * Float(p),
                                         idle.y + (ready.y - idle.y) * Float(p))
            
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
