//
//  StaticTerrainBody.swift
//  ZobbleBobble
//
//  Created by Rost on 22.08.2023.
//

import Foundation

class StaticTerrainBody: LiquidBody {
    private let liquidFadeMultiplier: Float = 0
    
    var chunks: [ChunkModel] { didSet { needsUpdate = true } }
    var scale: CGFloat = 1 { didSet { needsUpdate = true } }
    var offset: CGPoint = .zero { didSet { needsUpdate = true } }
    
    private var needsUpdate = true { didSet { updateTerrainPositions() } }
    private var positions: [SIMD2<Float32>] = []
    private var colors: [SIMD4<UInt8>] = []
    private var velocities: [SIMD2<Float32>] = []
    
    init(chunks: [ChunkModel]) {
        self.chunks = chunks
        super.init()
        
        updateTerrainPositions()
    }
    
    private func updateTerrainPositions() {
        invalidateRenderData()
        
        var newPositions: [SIMD2<Float32>] = []
        var newColors: [SIMD4<UInt8>] = []
        var newVelocities: [SIMD2<Float32>] = []
        
        for chunk in chunks {
            for particle in chunk.particles {
                let position = SIMD2(Float((particle.position.x * scale + offset.x)),
                                     Float((particle.position.y * scale + offset.y)))
                
                newVelocities.append(.zero)
                newColors.append(particle.movementColor)
                newPositions.append(position)
            }
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
        guard positions.count > 0 else {
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
        
        self.renderData = .init(particleRadius: Float(Settings.Physics.particleRadius * scale),
                                liquidFadeModifier: liquidFadeMultiplier,
                                scale: 1,
                                liquidCount: self.positions.count,
                                liquidPositions: positions,
                                liquidVelocities: velocities,
                                liquidColors: colors)
    }
}
