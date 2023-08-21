//
//  PlayerModel.swift
//  ZobbleBobble
//
//  Created by Rost on 20.08.2023.
//

import Foundation

class PlayerModel: Codable {
    var credits: UInt64 = 0
    var day: UInt64 = 0
    
    var planets = [PlanetModel]()
    var containers = [ContainerModel]()
    
    var selectedPlanetIndex: Int?
    var selectedContainerIndex: Int?
}

extension PlayerModel {
    var selectedContainer: ContainerModel? { selectedContainerIndex.map { containers[$0] } }
    var selectedPlanet: PlanetModel? { selectedPlanetIndex.map { planets[$0] } }
}
