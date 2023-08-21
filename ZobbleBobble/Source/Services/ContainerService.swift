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
        [generateContainer(for: player)]
    }
    
    private func generateContainer(for player: PlayerModel) -> ContainerModel {
        let count = 10
        let chunks = (0..<count).map { _ in self.chunkService.generateChunk() }
        
        let container = ContainerModel(missles: chunks, reward: 450)
        return container
    }
}
