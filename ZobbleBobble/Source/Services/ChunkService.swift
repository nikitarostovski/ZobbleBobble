//
//  ChunkService.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation
import Blueprints

final class ChunkService {
    private let blueprints: [ChunkBlueprintModel]
    
    init?(_ file: String) {
        if let levelDataPath = Bundle.main.path(forResource: "JSON/\(file)", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: levelDataPath), options: .mappedIfSafe)
                blueprints = try JSONDecoder().decode(Array<ChunkBlueprintModel>.self, from: data)
            } catch {
                print(error)
                return nil
            }
        } else {
            return nil
        }
        print("\(blueprints.count) blueprints loaded from '\(file).json'")
    }
    
    func generateChunk() -> ChunkModel {
        let blueprint = blueprints.randomElement()!
        let startImpulse = CGFloat.random(in: 1...3)
        return ChunkModel(blueprint: blueprint, startImpulse: startImpulse)
    }
}
