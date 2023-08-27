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
        case .organic: return 1
        case .sand: return 0.5
        case .rock: return 0.7
        case .water: return 1
        case .oil: return 1.2
        case .metal: return 1
        case .magma: return 1.1
        case .acid: return 1.1
        case .dust: return 0.5
        }
    }
    
    /// Threshold for metaballs alpha texture cropping
    public var cropThreshold: Float {
        switch self {
        case .organic: return 0.5
        case .sand: return 0.3
        case .rock: return 0.6
        case .water: return 0.5
        case .oil: return 0.35
        case .metal: return 0.5
        case .magma: return 0.6
        case .acid: return 0.5
        case .dust: return 0.3
        }
    }
    
    /// scale for alpha radius (when drawing metaballs)
    public var alphaTextureRadiusModifier: Float {
        switch self {
        case .organic: return 1
        case .sand: return 1.3
        case .rock: return 1
        case .water: return 1.2
        case .oil: return 1.2
        case .metal: return 1
        case .magma: return 1.3
        case .acid: return 1.2
        case .dust: return 1.2
        }
    }
    
    /// scale for movement texture radius (when drawing metaballs) for smoother/sharper movement pattern
    public var movmentTextureRadiusModifier: Float {
        switch self {
        case .organic: return 1
        case .sand: return 1
        case .rock: return 1
        case .water: return 1
        case .oil: return 1
        case .metal: return 1
        case .magma: return 1
        case .acid: return 1
        case .dust: return 1
        }
    }
    
    /// Threshold for movement channels color distribution [0...0.5]
    public var movementTextureThresold: Float {
        switch self {
        case .organic: return 0.25
        case .sand: return 0.25
        case .rock: return 0.25
        case .water: return 0.25
        case .oil: return 0.25
        case .metal: return 0.25
        case .magma: return 0.25
        case .acid: return 0.25
        case .dust: return 0.25
        }
    }
}
