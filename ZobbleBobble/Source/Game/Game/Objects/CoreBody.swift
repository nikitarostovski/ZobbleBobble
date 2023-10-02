//
//  CoreBody.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

import Foundation

class CoreBody: Body {
    var userInteractive: Bool { false }
    weak var physicsWorld: PhysicsWorld?
    private var actualRenderData: CoreRenderData?
    
    var renderData: CoreRenderData? {
        get {
            if let liquidPhysicsData = physicsWorld?.getRenderData() {
                actualRenderData = liquidPhysicsData.core
            }
            return actualRenderData
        }
        set {
            actualRenderData = newValue
        }
    }
    
    init(physicsWorld: PhysicsWorld?) {
        self.physicsWorld = physicsWorld
    }
}
