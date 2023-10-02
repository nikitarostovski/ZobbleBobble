//
//  PlanetService.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation
import Blueprints

final class PlanetService {
    private let chunkService = ChunkService("Planets")!
    
    func getAvaialablePlanets(for player: PlayerModel) -> [PlanetModel] {
        [generatePlanet(for: player),
         generatePlanet(for: player),
         generatePlanet(for: player)]
    }
    
    private func generatePlanet(for player: PlayerModel) -> PlanetModel {
        let gravityRadius: CGFloat = 100
        
        let limits = LimitationsModel(radiusLimit: .init(value: Float(gravityRadius * 0.5), fine: 1),
                                      sectorLimit: .init(value: [.init(startAngle: 0, sectorSize: 10)], fine: 2),
                                      materialWhitelist: .init(value: [.organic, .rock], fine: 4),
                                      totalParticleAmountLimit: .init(value: 2000, fine: 1),
                                      outerSpaceLimit: .init(value: .init(), fine: 1))
        
        let number = UInt8.random(in: UInt8.min...UInt8.max)
        
        let chunkData = [chunkService.generateChunk(options: [.solidOnly])]
        let chunks = chunkData
            .map { $0.0 }
        let cores = chunkData
            .compactMap { $0.1 }
        
        let planet = PlanetModel(name: "Planet #\(number)",
                                 price: 125,
                                 speed: 60,
                                 core: cores.first,
                                 chunks: chunks,
                                 limits: limits,
                                 gravityRadius: gravityRadius,
                                 gravityStrength: 1,
                                 particleRadius: Settings.Physics.particleRadius)
        return planet
    }
    
    
}
