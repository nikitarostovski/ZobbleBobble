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

protocol PhysicsWorldDelegate: AnyObject {
    func physicsWorldDidUpdate(particles: UnsafeRawPointer?, particleCount: Int)
}

class PhysicsWorld {
//    private let lock = NSLock()
    private let world: ZobbleWorld
    private let rotationStep: CGFloat
    private var renderData: RenderData
    
    private var lastUpdateDate: Date?
    
    weak var delegate: PhysicsWorldDelegate?
    
    init(size: CGSize, particleRadius: CGFloat, rotationStep: CGFloat, gravityRadius: CGFloat, gravityCenter: CGPoint) {
        self.rotationStep = rotationStep
        let size = CGSize(width: 300, height: 300)
        self.world = ZobbleWorld(size: size)
        self.renderData = RenderData(Float(particleRadius), 0, nil, nil)
    
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
        
        world.delegate = self
        
        for i in 0..<10 {
            for j in 0..<10 {
                let pos = CGPoint(x: i, y: j)

                var col = Colors.Materials.magma
                col.w = 255

                world.addParticle(withPos: pos, color: col)
            }
        }
    }
    
    func getRenderData() -> RenderData? {
        renderData
    }
    
    func addCircle(withPosition: CGPoint, radius: CGFloat, color: SIMD4<UInt8>) {
//        renderData.core = .init(
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
//        world.addParticle(withPos: pos, color: color)
    }
}

extension PhysicsWorld: ZobbleWorldDelegate {
    func worldDidUpdate(withParticles particles: UnsafeRawPointer?, count particleCount: Int32) {
//        renderData.core?.core.rotation += Float(rotationStep)
//        renderData.count = Int(particleCount)
//        renderData.particles = particles
//        
//        delegate?.physicsWorldDidUpdate(particles: particles, particleCount: Int(particleCount))
        
        let now = Date()
        if let lastUpdateDate = lastUpdateDate {
            let ms = Int(now.timeIntervalSince(lastUpdateDate) * 1000)
            print("Update. bodies: \(particleCount) time: \(ms)ms")
        }
        lastUpdateDate = now
    }
}
