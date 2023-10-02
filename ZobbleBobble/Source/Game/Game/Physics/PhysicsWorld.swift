//
//  PhysicsWorld.swift
//  ZobbleBobble
//
//  Created by Rost on 30.07.2023.
//

import Foundation

protocol PhysicsWorld: AnyObject {
    typealias RenderData = (particleRadius: Float,
                            liquidCount: Int,
                            liquidPositions: UnsafeMutableRawPointer,
                            liquidVelocities: UnsafeMutableRawPointer,
                            liquidColors: UnsafeMutableRawPointer,
                            core: CoreRenderData?)
    
    func update(_ time: CFTimeInterval)
    func getRenderData() -> RenderData?
    
    func addCircle(withPosition: CGPoint, radius: CGFloat, color: SIMD4<UInt8>)
    
    func addParticle(withPosition: CGPoint,
                     color: SIMD4<UInt8>,
                     flags: UInt32,
                     isStatic: Bool,
                     gravityScale: CGFloat,
                     freezeVelocityThreshold: CGFloat,
                     becomesLiquidOnContact: Bool,
                     explosionRadius: CGFloat,
                     shootImpulse: CGFloat)
}
