//
//  LiquidBody.swift
//  ZobbleBobble
//
//  Created by Rost on 03.08.2023.
//

import Foundation

class LiquidBody: Body {
    var userInteractive: Bool = false
    var renderData: LiquidRenderData? = nil
    var uniqueMaterials: [MaterialType] = []
}
