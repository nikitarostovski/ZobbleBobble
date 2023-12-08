//
//  TerrainBody.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation

protocol TerrainBodyDelegate: AnyObject {
    func terrainBodyDidUpdate(particles: UnsafeRawPointer?, particleCount: Int)
}

class TerrainBody: LiquidBody {
    let liquidFadeModifier: Float
    
    weak var delegate: TerrainBodyDelegate?
    weak var physicsWorld: PhysicsWorld?
    
    private var actualRenderData: TerrainRenderData?
    
    override var renderData: TerrainRenderData? {
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
        
        physicsWorld?.delegate = self
    }
}

extension TerrainBody: PhysicsWorldDelegate {
    func physicsWorldDidUpdate(particles: UnsafeRawPointer?, particleCount: Int) {
        delegate?.terrainBodyDidUpdate(particles: particles, particleCount: particleCount)
    }
}
