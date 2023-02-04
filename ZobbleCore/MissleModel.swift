//
//  MissleModel.swift
//  ZobbleCore
//
//  Created by Rost on 03.02.2023.
//

import Foundation

public struct MissleModel: Codable {
    public let material: MaterialType
    public internal(set) var shape: ShapeModel
}
