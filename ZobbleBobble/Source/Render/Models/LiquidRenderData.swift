//
//  LiquidRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct TerrainRenderData {
    let particleRadius: Float
    let liquidFadeModifier: Float
    let scale: Float
    
    let count: Int
    let particles: UnsafeRawPointer?
}
