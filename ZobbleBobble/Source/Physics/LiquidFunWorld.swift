//
//  LiquidFunWorld.swift
//  ZobbleBobble
//
//  Created by Rost on 30.07.2023.
//

import Foundation
import ZobblePhysics

class LiquidFunWorld: PhysicsWorld {
    private let queue = DispatchQueue(label: "liquidfunworld.update", qos: .userInteractive)
    
    private let world: ZPWorld
    private let particleRadius: CGFloat
    
    init(particleRadius: CGFloat, rotationStep: CGFloat, gravityRadius: CGFloat, gravityCenter: CGPoint) {
        self.particleRadius = particleRadius
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
    }
    
    func getRenderData() -> RenderData? {
        var result: RenderData?
        
        let group = DispatchGroup()
        group.enter()
        world.requestRenderData { [particleRadius] count, positions, velocities, colors in
            if count > 0, let positions = positions, let velocities = velocities, let colors = colors {
                result = (particleRadius: Float(particleRadius),
                          liquidCount: Int(count),
                          liquidPositions: positions,
                          liquidVelocities: velocities,
                          liquidColors: colors)
            }
            group.leave()
        }
        group.wait()
        
        return result
    }
    
    func update(_ time: CFTimeInterval) {
        queue.async { [weak self] in
            guard let self = self else { return }
            autoreleasepool {
                self.world.worldStep(time,
                                     velocityIterations: Int32(Settings.Physics.velocityIterations),
                                     positionIterations: Int32(Settings.Physics.positionIterations),
                                     particleIterations: Int32(Settings.Physics.particleIterations))
            }
        }
    }
    
    func addParticle(withPosition: CGPoint, color: SIMD4<UInt8>, flags: UInt32, isStatic: Bool, gravityScale: CGFloat, freezeVelocityThreshold: CGFloat, becomesLiquidOnContact: Bool, explosionRadius: CGFloat, shootImpulse: CGFloat) {
        queue.async { [weak self] in
            self?.world.addParticle(withPosition: withPosition,
                                    color: CGRect(color),
                                    flags: flags,
                                    isStatic: isStatic,
                                    gravityScale: gravityScale,
                                    freezeVelocityThreshold: freezeVelocityThreshold,
                                    becomesLiquidOnContact: becomesLiquidOnContact,
                                    explosionRadius: explosionRadius,
                                    shootImpulse: shootImpulse)
        }
    }
}
