//
//  ShipModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation

struct ShipModel: Codable {
    var containers = [ContainerModel]()
    var loadedContainerIndex: Int?
}
