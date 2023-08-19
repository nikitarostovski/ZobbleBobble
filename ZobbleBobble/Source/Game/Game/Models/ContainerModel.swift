//
//  ContainerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation
import Levels

struct ContainerModel: Codable {
    var missles: [ChunkModel]
}

extension ContainerModel {
    var uniqueMaterials: [MaterialType] { missles.flatMap { $0.particles.map { $0.material } } }
}

extension ContainerModel {
    init(level: LevelModel) {
        self.missles = level.missleChunks
    }
}
