//
//  PlayerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation

struct PlayerModel {
    var availablePlanets: [PlanetModel]
    var ship: ShipModel
    var day: Int
    
    var selectedContainer: ContainerModel? { ship.loadedContainerIndex.map { ship.containers[$0] } }
}
