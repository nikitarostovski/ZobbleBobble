//
//  LevelManager.swift
//  LevelManager
//
//  Created by Rost on 14.11.2022.
//

import UIKit

enum LevelManagerError: Error {
    case invaildInput
}

public final class LevelManager {
    public var allLevelPacks: [PackModel] = []
    
    public init(levelData: Data) throws {
        guard let levelPackModels = try? JSONDecoder().decode(Array<PackModel>.self, from: levelData) else { throw LevelManagerError.invaildInput }
        self.allLevelPacks = levelPackModels
    }
}
