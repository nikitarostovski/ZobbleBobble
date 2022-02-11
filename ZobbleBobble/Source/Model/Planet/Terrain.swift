//
//  Terrain.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 25.12.2021.
//

import UIKit

final class Terrain {
    var chunks: [Chunk]
    var core: Chunk?
    
    init(core: Chunk?, chunks: [Chunk]) {
        self.core = core
        self.chunks = chunks
    }
}
