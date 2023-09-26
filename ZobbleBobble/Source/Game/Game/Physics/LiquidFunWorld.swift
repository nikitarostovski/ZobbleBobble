//
//  LiquidFunWorld.swift
//  ZobbleBobble
//
//  Created by Rost on 30.07.2023.
//

import Foundation
import ZobblePhysics

class LiquidFunWorld {
    private let queue = DispatchQueue(label: "liquidfunworld.update", qos: .userInteractive)
    
    private let world: ZPWorld
    private let particleRadius: CGFloat
    
    private var matrix: CellularMatrix
    
    init(width: Int, height: Int, rotationStep: CGFloat, gravityRadius: CGFloat, gravityCenter: CGPoint) {
        self.particleRadius = 0.5
        
        let def = ZPWorldDef()
        def.shotImpulseModifier = Settings.Physics.missleShotImpulseModifier
        def.gravityScale = float32(Settings.Physics.gravityModifier)
        def.rotationStep = rotationStep
        def.maxCount = int32(Settings.Physics.maxParticleCount)
        def.center = gravityCenter
        def.gravityRadius = gravityRadius
        def.radius = Float(particleRadius)
        
        def.destroyByAge = false
        def.ejectionStrength = 8
        def.powderStrength = 2
        
        self.world = ZPWorld(worldDef: def)
        self.matrix = CellularMatrix(width: width, height: height)
        
        
//        for y in 0..<height {
//            for x in 0..<width {
//                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
//                    self.matrix.set(x, y, Stone(x: x, y: y))
//                }
//            }
//        }
//
//        let squareSize = 20
//
//        for i in (-squareSize / 2)..<(squareSize / 2) {
//            for j in (-squareSize / 2)..<(squareSize / 2) {
//                let x = width / 2 + i
//                let y = height / 2 + j
//                self.matrix.set(x, y, Sand(x: x, y: y))
//            }
//        }
    }
    
    func step(_ time: CFTimeInterval) {
//        queue.async { [weak self] in
//            guard let self = self else { return }
            autoreleasepool {
                self.world.worldStep(time,
                                     velocityIterations: Int32(Settings.Physics.velocityIterations),
                                     positionIterations: Int32(Settings.Physics.positionIterations),
                                     particleIterations: Int32(Settings.Physics.particleIterations))
            }
//        }
    }
    
    func addParticle(withPosition: CGPoint, color: SIMD4<UInt8>, flags: UInt32, isStatic: Bool, gravityScale: CGFloat, freezeVelocityThreshold: CGFloat, becomesLiquidOnContact: Bool, explosionRadius: CGFloat, shootImpulse: CGFloat) {
//        queue.async { [weak self] in
            self.world.addParticle(withPosition: withPosition,
                                    color: CGRect(color),
                                    flags: flags,
                                    isStatic: isStatic,
                                    gravityScale: gravityScale,
                                    freezeVelocityThreshold: freezeVelocityThreshold,
                                    becomesLiquidOnContact: becomesLiquidOnContact,
                                    explosionRadius: explosionRadius,
                                    shootImpulse: shootImpulse)
//        }
    }
    
    var renderData: CellsRenderData? {
        autoreleasepool {
            updateMatrix()
        }
        return lastRenderData
    }
    
    private var lastRenderData: CellsRenderData?
    
    private func updateMatrix() {
        world.requestRenderData { [weak self] count, positions, colors, velocities in
            guard let self = self else { return }
            let texture = matrix.update(count: Int(count), positions: positions, colors: colors, velocities: velocities)
            lastRenderData = CellsRenderData(gridTexture: texture)
        }
    }
}
