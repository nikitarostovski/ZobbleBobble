//
//  MaterialModel+Rendering.swift
//  ZobbleBobble
//
//  Created by Rost on 27.08.2023.
//

import Foundation

extension MaterialType {
    public var blurModifier: CGFloat {
        switch self {
        case .sand, .dust:
            return 0.4
        case .rock, .metal:
            return 1
        case .magma, .organic:
            return 1.5
        case .water, .acid, .oil:
            return 2
        }
//        switch self {
//        case .organic: return 1
//        case .sand: return 0.5
//        case .rock: return 0.7
//        case .water: return 1
//        case .oil: return 1.2
//        case .metal: return 1
//        case .magma: return 1.1
//        case .acid: return 1.1
//        case .dust: return 0.5
//        }
    }
    
    /// Threshold for metaballs alpha texture cropping
    public var cropThreshold: Float {
        switch self {
        case .sand, .dust:
            return 0.5
        case .rock, .metal:
            return 0.4
        case .magma, .organic:
            return 0.4
        case .water, .acid, .oil:
            return 0.4
        }
//        switch self {
//        case .organic: return 0.5
//        case .sand: return 0.3
//        case .rock: return 0.6
//        case .water: return 0.5
//        case .oil: return 0.35
//        case .metal: return 0.5
//        case .magma: return 0.6
//        case .acid: return 0.5
//        case .dust: return 0.3
//        }
    }
    
    /// scale for alpha radius (when drawing metaballs)
    public var alphaTextureRadiusModifier: Float {
        switch self {
        case .sand, .dust:
            return 1
        case .rock, .metal:
            return 1
        case .magma, .organic:
            return 1
        case .water, .acid, .oil:
            return 1
        }
    }
    
    /// scale for movement texture radius (when drawing metaballs) for smoother/sharper movement pattern
    public var movmentTextureRadiusModifier: Float {
        switch self {
        case .sand, .dust:
            return 1
        case .rock, .metal:
            return 1
        case .magma, .organic:
            return 1
        case .water, .acid, .oil:
            return 1
        }
    }
    
    /// Threshold for movement channels color distribution [0...0.5]
    public var movementTextureThresold: Float {
        switch self {
        case .sand, .dust:
            return 0.2
        case .rock, .metal:
            return 0.2
        case .magma, .organic:
            return 0.2
        case .water, .acid, .oil:
            return 0.2
        }
    }
}
