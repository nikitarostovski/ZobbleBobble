//
//  CoreModel+Blueprints.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.09.2023.
//

import Foundation
import Blueprints

extension CoreModel {
    init(blueprint: CoreBlueprintModel) {
        self.x = blueprint.x
        self.y = blueprint.y
        self.radius = blueprint.radius
    }
}
