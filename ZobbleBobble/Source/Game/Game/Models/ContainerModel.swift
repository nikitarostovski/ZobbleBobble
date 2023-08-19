//
//  ContainerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation
import Levels

struct ContainerModel {
    var missles: [ChunkModel]
    
    var uniqueMaterials: [MaterialType] { missles.flatMap { $0.particles.map { $0.material } } }
}
