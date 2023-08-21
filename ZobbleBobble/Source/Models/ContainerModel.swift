//
//  ContainerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation

struct ContainerModel: Codable {
    var missles: [ChunkModel]
    var reward: UInt64
}

extension ContainerModel {
    var uniqueMaterials: [MaterialType] { missles.flatMap { $0.particles.map { $0.material } } }
}
