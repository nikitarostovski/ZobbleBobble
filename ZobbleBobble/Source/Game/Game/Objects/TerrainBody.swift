//
//  TerrainBody.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation
import Levels

class TerrainBody: LiquidBody {
    let liquidFadeModifier: Float
    
    weak var physicsWorld: PhysicsWorld?
    
    private var actualRenderData: LiquidRenderData?
    
    override var renderData: LiquidRenderData? {
        get {
            if let liquidPhysicsData = physicsWorld?.getRenderData() {
                actualRenderData = .init(particleRadius: liquidPhysicsData.particleRadius,
                                         liquidFadeModifier: liquidFadeModifier,
                                         scale: Float(Settings.Physics.scale),
                                         liquidCount: liquidPhysicsData.liquidCount,
                                         liquidPositions: liquidPhysicsData.liquidPositions,
                                         liquidVelocities: liquidPhysicsData.liquidVelocities,
                                         liquidColors: liquidPhysicsData.liquidColors)
            }
            return actualRenderData
        }
        set {
            actualRenderData = newValue
        }
    }
    
    init(liquidFadeModifier: Float = Settings.Graphics.fadeMultiplier, physicsWorld: PhysicsWorld?, uniqueMaterials: [MaterialType]) {
        self.physicsWorld = physicsWorld
        self.liquidFadeModifier = liquidFadeModifier
        
        super.init()
        
        self.uniqueMaterials = uniqueMaterials
    }
}
