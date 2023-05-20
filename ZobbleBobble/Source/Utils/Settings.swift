//
//  Settings.swift
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

import Foundation

enum Settings {
    enum Camera {
        static let levelCameraScale: CGFloat = 1
        static let levelsMenuCameraScale: CGFloat = 2
        static let packsMenuCameraScale: CGFloat = 3
        
        static let levelCenterOffset: CGFloat = 50
        
        static let starMissleCenterOffset: CGFloat = 25
        static let starMissleDeadZone: CGFloat = 40
        
        static let starLevelScale: CGFloat = 1
        static let starLevelMenuScale: CGFloat = 0.25
        static let starPackMenuScale: CGFloat = 0.5
        
        static let planetLevelScale: CGFloat = 1
        static let planetLevelMenuScale: CGFloat = 0.25
        static let planetPackMenuScale: CGFloat = 0
        
        static let planetMaterialsUpscaleInGame: CGFloat = 1.75
        
        static let starLevelAngle: CGFloat = CGFloat(90).radians
        static let starLevelMenuAngle: CGFloat = CGFloat(30).radians
        static let starPackMenuAngle: CGFloat = CGFloat(20).radians
        
        static let planetLevelAngle: CGFloat = CGFloat(90).radians
        static let planetLevelMenuAngle: CGFloat = CGFloat(20).radians
        static let planetPackMenuAngle: CGFloat = CGFloat(90).radians
        
        static let menuAnimationDuration: Double = 0.3
        static let menuAnimationEasing: Curve = .sine
        
        static let shotAnimationDuration: Double = 0.25
        static let shotAnimationEasing: Curve = .sine
    }
    
    enum Physics {
        static let maxParticleCount = 10000
        static let maxMaterialCount = 50
        
        static let velocityIterations = 8
        static let positionIterations = 3
        static let particleIterations = 2
        
        static let gravityModifier: CGFloat = 5
        static let missleShotImpulseModifier: CGFloat = 100_000
        
        static let speedThresholdModifier: CGFloat = 35
    }
    
    enum Graphics {
        static let resolutionDownscale: CGFloat = 1
        
        static let metaballsDownscale: Float = 0.25
        static let metaballsBlurKernelSize: Int = 2
        
        static let fadeMultiplier: Float = 0.2//0.3
        
        static let planetSurfaceThickness: Int = 12
        static let inflightBufferCount = 3
    }
}
