//
//  Game+RenderViewDataSource.swift
//  ZobbleBobble
//
//  Created by Rost on 01.08.2023.
//

import Foundation

extension Game: RenderViewDataSource {
    var visibleBodies: [any Body] {
        stars + terrains + missles
    }
    
    var cameraX: Float {
        Float(cameraState.camera.x)
    }
    
    var cameraY: Float {
        Float(cameraState.camera.y)
    }
    
    var cameraScale: Float {
        Float(cameraState.cameraScale)
    }
}
