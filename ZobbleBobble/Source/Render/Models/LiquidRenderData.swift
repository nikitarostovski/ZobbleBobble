//
//  LiquidRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct LiquidRenderData {
    let particleRadius: Float
    let liquidFadeModifier: Float
    let scale: Float
    
    let liquidCount: Int
    let liquidPositions: UnsafeMutableRawPointer
    let liquidVelocities: UnsafeMutableRawPointer
    let liquidColors: UnsafeMutableRawPointer
}
