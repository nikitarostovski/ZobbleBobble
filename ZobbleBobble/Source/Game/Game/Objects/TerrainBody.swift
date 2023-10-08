//
//  TerrainBody.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation

class TerrainBody: LiquidBody {
    let liquidFadeModifier: Float
    
    weak var physicsWorld: PhysicsWorld?
    
    private var actualRenderData: LiquidRenderData?
    
    override var renderData: LiquidRenderData? {
        get {
            if let liquidPhysicsData = physicsWorld?.getRenderData() {
                actualRenderData = .init(particleRadius: liquidPhysicsData.radius,
                                         liquidFadeModifier: liquidFadeModifier,
                                         scale: 1,
                                         count: liquidPhysicsData.count,
                                         particles: liquidPhysicsData.particles)
            }
            return actualRenderData
        }
        set {
            actualRenderData = newValue
        }
    }
    
    init(liquidFadeModifier: Float = Settings.Graphics.fadeMultiplier, physicsWorld: PhysicsWorld?) {
        self.physicsWorld = physicsWorld
        self.liquidFadeModifier = liquidFadeModifier
        
        super.init()
    }
}
