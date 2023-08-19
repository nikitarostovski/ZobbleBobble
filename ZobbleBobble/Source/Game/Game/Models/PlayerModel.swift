//
//  PlayerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation

struct PlayerModel: Codable {
    var credits: UInt64
    var availablePlanets = [PlanetModel]()
    var selectedPlanetIndex: Int = 0
    var ship = ShipModel()
    var day: Int = 0
}

extension PlayerModel {
    var selectedContainer: ContainerModel? { ship.loadedContainerIndex.map { ship.containers[$0] } }
    var selectedPlanet: PlanetModel { availablePlanets[selectedPlanetIndex] }
}
