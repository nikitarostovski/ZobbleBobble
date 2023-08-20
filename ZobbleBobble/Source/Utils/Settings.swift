//
//  Settings.swift
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

import Foundation

enum Settings {
    enum Camera {
        static let sceneHeight: CGFloat = 960 / Graphics.resolutionDownscale
        
        static let levelCameraScale: CGFloat = 1
        static let levelsMenuCameraScale: CGFloat = 2
        static let packsMenuCameraScale: CGFloat = 3
        
        static let levelCenterOffset: CGFloat = -120 / Graphics.resolutionDownscale
        static let gunCenterOffset: CGFloat = 560 / Graphics.resolutionDownscale
        
        static let gunRadius: CGFloat = 100 / Graphics.resolutionDownscale
        static let gunMissleCenterOffset: CGFloat = 10 / Graphics.resolutionDownscale
        static let gunMissleDeadZone: CGFloat = 20 / Graphics.resolutionDownscale
        
        static let missleRadiusShiftInsideStar: CGFloat = 3
        static let missleAngleShiftInsideStar = CGFloat(5).radians
        static let missleParticleMaxSpeedModifier: CGFloat = 2
        
//        static let starLevelScale: CGFloat = 1
//        static let starLevelMenuScale: CGFloat = 0.25
//        static let starPackMenuScale: CGFloat = 0.5
//
//        static let planetLevelScale: CGFloat = 1
//        static let planetLevelMenuScale: CGFloat = 0.25
//        static let planetPackMenuScale: CGFloat = 0
        
        static let gunMaterialsUpscaleInGame: CGFloat = 1.75
        
//        static let starLevelAngle: CGFloat = CGFloat(90).radians
//        static let starLevelMenuAngle: CGFloat = CGFloat(30).radians
//        static let starPackMenuAngle: CGFloat = CGFloat(20).radians
//
//        static let planetLevelAngle: CGFloat = CGFloat(90).radians
//        static let planetLevelMenuAngle: CGFloat = CGFloat(20).radians
//        static let planetPackMenuAngle: CGFloat = CGFloat(90).radians
        
        static let sceneTransitionDuration: Double = 0.15
        static let sceneTransitionEasing: Curve = .sine
        
        static let shotAnimationDuration: Double = 0.4
        static let shotAnimationEasing: Curve = .sine
    }
    
    enum Physics {
        static let scale: CGFloat = 100_000
        
        static let maxParticleCount = 10_000
        static let maxMaterialCount = 50
        
        static let velocityIterations = 8
        static let positionIterations = 3
        static let particleIterations = 3
        
        static let gravityModifier: CGFloat = 2_000 * scale
        static let missleShotImpulseModifier: CGFloat = 4_000 * scale
        
        static let freezeThresholdModifier: CGFloat = 30 * scale
    }
    
    enum Graphics {
        static let resolutionDownscale: CGFloat = 1
        
        static let metaballsDownscale: Float = 0.7
        static let metaballsBlurSigma: Float = 1.5
        
        static let fadeMultiplier: Float = 0.3
        
        static let inflightBufferCount = 3
        static let dotMaskType: DotMask.MaskType = .trisectedShifted
    }
}
