//
//  Settings.swift
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

import Foundation

// TODO: nested structs
final class Settings {
    static let levelCameraScale: CGFloat = 1
    static let levelsMenuCameraScale: CGFloat = 2
    static let packsMenuCameraScale: CGFloat = 3
    
//    static let physicsScale: CGFloat = 0.1
//    static let worldWidth: CGFloat = 100
    
    static let resolutionDownscale: CGFloat = 1
    
    static let liquidMetaballsDownscale: Float = 0.35
    static let liquidMetaballsBlurKernelSize: Int = 1
    
    static let liquidFadeMultiplier: Float = 0.3
    
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
    
    static let inflightBufferCount = 3
    static let maxParticleCount = 10000
    static let maxMaterialCount = 50
    
    static let physicsVelocityIterations = 8
    static let physicsPositionIterations = 3
    static let physicsParticleIterations = 2
    
    static let physicsGravityModifier: CGFloat = 5
    static let physicsMissleShotImpulseModifier: CGFloat = 100_000
    
    static let physicsSpeedThresholdModifier: CGFloat = 35
}
