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
            generateContainer(for: player, containerIndex: $0, containerTotalCount: count)
        }
    }
    
    private func generateContainer(for player: PlayerModel, containerIndex: Int, containerTotalCount: Int) -> ContainerModel {
        let progress = CGFloat(containerIndex) / CGFloat(containerTotalCount)
        
        let count = containerIndex + 3
        let chunks = (0..<count).map { _ in self.chunkService.generateChunk() }
        
        let container = ContainerModel(missles: chunks, reward: max(100, UInt64(650 * progress)))
        return container
    }
}
