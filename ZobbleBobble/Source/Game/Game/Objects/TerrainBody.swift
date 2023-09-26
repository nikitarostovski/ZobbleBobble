//
//  TerrainBody.swift
//  ZobbleBobble
//
//  Created by Rost on 31.07.2023.
//

import Foundation

class TerrainBody: Body {
    var userInteractive: Bool { false }

    private weak var physicsWorld: LiquidFunWorld?

    var renderData: CellsRenderData? {
        physicsWorld?.renderData
    }

    init(physicsWorld: LiquidFunWorld?) {
        self.physicsWorld = physicsWorld
    }
}
