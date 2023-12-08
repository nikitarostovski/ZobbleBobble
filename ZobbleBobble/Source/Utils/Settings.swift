//
//  Settings.swift
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

import Foundation

enum Settings {
#if DEBUG
    static let isDebug = true
#else
    static let isDebug = false
#endif
    
    // TODO: Rename to `Scene`
    enum Camera {
        static let sceneHeight: CGFloat = 699
        
        static let levelCenterOffset: CGFloat = -50
        static let gunCenterOffset: CGFloat = 250
        
        static let gunRadius: CGFloat = 30
        
        static let missleParticleMaxSpeedModifier: CGFloat = 2
        
        static let sceneTransitionDuration: Double = 0.15
        static let shotAnimationDuration: Double = 0.4
    }
    
    enum Physics {
        static let particleRadius: CGFloat = 0.5
        
        static let maxParticleCount = 100_000
        static let maxMaterialCount = 50
        
        static let velocityIterations = 6
        static let positionIterations = 2
        static let particleIterations = 3
        
        static let gravityModifier: CGFloat = 4_000
        static let missleShotImpulseModifier: CGFloat = 4_000
        
        static let freezeThresholdModifier: CGFloat = 20
    }
    
    enum Graphics {
        static let metaballsDownscale: Float = 0.8
        static let metaballsBlurSigma: Float = 1
        
        static let fadeMultiplier: Float = 0//0.3
        
        static let inflightBufferCount = 3
        
        static let postprocessingEnabled = !Settings.isDebug
        static let dotMaskType: DotMask.MaskType = .trisectedShifted
    }
}
