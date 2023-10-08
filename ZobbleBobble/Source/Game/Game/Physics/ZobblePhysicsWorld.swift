//
//  ZobblePhysicsWorld.swift
//  ZobbleBobble
//
//  Created by Rost on 30.07.2023.
//

import Foundation
import ZobblePhysics

typealias RenderData = (radius: Float,
                        count: Int,
                        particles: UnsafeRawPointer?,
                        core: CoreRenderData?)

class PhysicsWorld {
    private let world: ZobbleWorld
    private let particleRadius: CGFloat
    private let rotationStep: CGFloat
    private var coreRenderData: CoreRenderData?
    
    init(size: CGSize, particleRadius: CGFloat, rotationStep: CGFloat, gravityRadius: CGFloat, gravityCenter: CGPoint) {
        self.particleRadius = particleRadius
        self.rotationStep = rotationStep
        self.world = ZobbleWorld(size: size)
        
//        let def = ZPWorldDef()
//        def.shotImpulseModifier = Settings.Physics.missleShotImpulseModifier
//        def.gravityScale = float32(Settings.Physics.gravityModifier)
//        def.rotationStep = rotationStep
//        def.maxCount = int32(Settings.Physics.maxParticleCount)
//        def.center = gravityCenter
//        def.gravityRadius = gravityRadius
//        def.radius = Float(particleRadius)
//
//        def.destroyByAge = false
//        def.ejectionStrength = 8
//        def.powderStrength = 2
//
//        self.world = ZPWorld(worldDef: def)
        
        for i in 0..<10 {
            for j in 0..<10 {
                let pos = CGPoint(x: i, y: j)

                var col = Colors.Materials.magma
                col.w = 255

                world.addParticle(pos, color: col)
            }
        }
    }
    
    func getRenderData() -> RenderData? {
        return RenderData(
            radius: Float(particleRadius),
            count: world.particleCount,
            particles: world.renderData,
            core: coreRenderData
        )
    }
    
    func update(_ time: CFTimeInterval) {
        coreRenderData?.core.rotation += Float(rotationStep)
        world.step(time)
    }
    
    func addCircle(withPosition: CGPoint, radius: CGFloat, color: SIMD4<UInt8>) {
//        coreRenderData = .init(
//            core: .init(
//                center: .init(Float(withPosition.x), Float(withPosition.y)),
//                radius: Float(radius),
//                rotation: 0
//            ),
//            scale: 1
//        )
//        world.addCircle(withCenter: withPosition, radius: radius, color: CGRect(color))
    }
    
    func addParticle(_ pos: CGPoint, _ color: SIMD4<UInt8>) {
//        print("Add particle at \(pos) \(color)")
//        world.addParticle(pos, color: color)
    }
}
