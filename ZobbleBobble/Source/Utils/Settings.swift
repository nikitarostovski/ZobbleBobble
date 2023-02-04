//
//  Settings.swift
//  ZobbleBobble
//
//  Created by Rost on 24.01.2023.
//

import Foundation

// TODO: nested structs
final class Settings {
    static let resolutionDownscale: CGFloat = 7
    
    static let liquidMetaballsDownscale: Float = 1
    
    static let levelCenterOffset: CGFloat = 50
    
    static let starLevelScale: CGFloat = 1
    static let starLevelMenuScale: CGFloat = 0.25
    static let starPackMenuScale: CGFloat = 0.5
    
    static let planetLevelScale: CGFloat = 1
    static let planetLevelMenuScale: CGFloat = 0.25
    static let planetPackMenuScale: CGFloat = 0
    
    static let starLevelAngle: CGFloat = CGFloat(90).radians
    static let starLevelMenuAngle: CGFloat = CGFloat(30).radians
    static let starPackMenuAngle: CGFloat = CGFloat(20).radians
    
    static let planetLevelAngle: CGFloat = CGFloat(90).radians
    static let planetLevelMenuAngle: CGFloat = CGFloat(20).radians
    static let planetPackMenuAngle: CGFloat = CGFloat(90).radians
    
    static let menuAnimationDuration: Double = 0.3
    static let menuAnimationEasing: Curve = .sine
    
    static let shotAnimationDuration: Double = 0.15
    static let shotAnimationEasing: Curve = .sine
}
