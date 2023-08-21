//
//  Game.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

protocol Game: AnyObject {
    var player: PlayerModel { get }
    
    func addContainer(_ container: ContainerModel)
    @discardableResult
    func removeContainer(_ index: Int) -> Bool
    @discardableResult
    func selectContainer(_ index: Int) -> Bool
    func clearSelectedContainer()
    
    func addPlanet(_ planet: PlanetModel)
    @discardableResult
    func removePlanet(_ index: Int) -> Bool
    @discardableResult
    func selectPlanet(_ index: Int) -> Bool
    func clearSelectedPlanet()
}
