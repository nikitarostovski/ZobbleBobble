//
//  ChunkService.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

final class ChunkService {
    private let preloadedChunks: [ChunkModel]
    
    init?(_ file: String) {
        if let levelDataPath = Bundle.main.path(forResource: file, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: levelDataPath), options: .mappedIfSafe)
                preloadedChunks = try JSONDecoder().decode(Array<ChunkModel>.self, from: data)
            } catch {
                print(error)
                return nil
            }
        } else {
            return nil
        }
        print("\(preloadedChunks.count) chunks loaded from '\(file).json'")
    }
    
    func generateChunk() -> ChunkModel {
        preloadedChunks.randomElement()!
    }
}
