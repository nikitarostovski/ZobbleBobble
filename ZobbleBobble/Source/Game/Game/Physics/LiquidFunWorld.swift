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
    
    private var coreRenderData: CoreRenderData?
    
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
        
        world.requestRenderData { [weak self] particleCount, particlePositions, particleVelocities, particleColors, _, _, _, _ in
            guard let self = self else { return }
            if particleCount > 0,
               let particlePositions = particlePositions,
               let particleVelocities = particleVelocities,
               let particleColors = particleColors {
                
                result = (particleRadius: Float(particleRadius),
                          liquidCount: Int(particleCount),
                          liquidPositions: particlePositions,
                          liquidVelocities: particleVelocities,
                          liquidColors: particleColors,
                          core: coreRenderData
                )
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
    
    func addCircle(withPosition: CGPoint, radius: CGFloat, color: SIMD4<UInt8>) {
        queue.async { [weak self] in
            self?.coreRenderData = .init(
                core: .init(
                    center: .init(Float(withPosition.x), Float(withPosition.y)),
                    radius: Float(radius)
                ),
                scale: Float(Settings.Physics.scale)
            )
            self?.world.addCircle(withCenter: withPosition, radius: radius, color: CGRect(color))
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
