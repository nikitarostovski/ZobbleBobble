//
//  CoreRenderData.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

import Foundation

struct CoreRenderData {
    struct Core {
        let center: SIMD2<Float>
        let radius: Float
    }
    
    let core: Core
    let scale: Float
}
