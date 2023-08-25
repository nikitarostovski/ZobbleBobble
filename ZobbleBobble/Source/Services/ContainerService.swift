//
//  ContainerService.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

final class ContainerService {
    private let chunkService = ChunkService("Missles")!
    
    func getAvaialableContainers(for player: PlayerModel) -> [ContainerModel] {
        let count = 5
        return (0..<count).map {
            generateContainer(for: player, options: [$0 == (count - 1) ? .liquidOnly : .solidOnly])
        }
    }
    
    private func generateContainer(for player: PlayerModel, options: [ChunkService.GenerationOption]) -> ContainerModel {
        let count = 12
        let chunks = (0..<count).map { _ in self.chunkService.generateChunk(options: options) }
        
        let container = ContainerModel(missles: chunks, reward: 640)
        return container
    }
}
