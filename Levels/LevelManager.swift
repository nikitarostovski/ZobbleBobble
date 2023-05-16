//
//  LevelManager.swift
//  LevelManager
//
//  Created by Rost on 14.11.2022.
//

import Foundation

enum LevelManagerError: Error {
    case invaildInput
}

public final class LevelManager {
    public var allLevelPacks: [PackModel] = []
    
    public init(levelData: Data) throws {
        do {
            let levelPackModels = try JSONDecoder().decode(Array<PackModel>.self, from: levelData)
            self.allLevelPacks = levelPackModels
        } catch {
            print(error)
            throw error
        }
    }
}
