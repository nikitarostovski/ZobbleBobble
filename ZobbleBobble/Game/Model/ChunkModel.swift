//
//  ChunkModel.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 17.11.2020.
//

import Foundation

struct ChunkModel {
 
    static let size: Float = 100
    
    var position: PointModel
    var obstacles: [ObstacleModel]
    
    static func generateChunk(at position: PointModel) -> ChunkModel {
//        let chunk = ChunkModel(position: position, obstacles: [
//            ObstacleModel(points: [
//                PointModel(x: 0, y: 0),
//                PointModel(x: 24, y: 0),
//                PointModel(x: 40, y: 16),
//                PointModel(x: 32, y: 36),
//                PointModel(x: 24, y: 40),
//                PointModel(x: 0, y: 40),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 24, y: 0),
//                PointModel(x: 64, y: 0),
//                PointModel(x: 64, y: 12),
//                PointModel(x: 40, y: 16),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 64, y: 0),
//                PointModel(x: 100, y: 0),
//                PointModel(x: 100, y: 28),
//                PointModel(x: 80, y: 28),
//                PointModel(x: 64, y: 12),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 24, y: 40),
//                PointModel(x: 28, y: 64),
//                PointModel(x: 0, y: 64),
//                PointModel(x: 0, y: 40),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 0, y: 64),
//                PointModel(x: 28, y: 64),
//                PointModel(x: 48, y: 72),
//                PointModel(x: 48, y: 104),
//                PointModel(x: 0, y: 104),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 0, y: 104),
//                PointModel(x: 48, y: 104),
//                PointModel(x: 68, y: 120),
//                PointModel(x: 68, y: 124),
//                PointModel(x: 0, y: 124),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 68, y: 120),
//                PointModel(x: 100, y: 100),
//                PointModel(x: 100, y: 124),
//                PointModel(x: 68, y: 124),
//            ]),
//            ObstacleModel(points: [
//                PointModel(x: 100, y: 100),
//                PointModel(x: 76, y: 80),
//                PointModel(x: 80, y: 28),
//                PointModel(x: 100, y: 28),
//            ]),
//
//
//            ObstacleModel(points: [
//                PointModel(x: 58, y: 97),
//                PointModel(x: 68, y: 104),
//                PointModel(x: 80, y: 97),
//                PointModel(x: 60, y: 80),
//            ]),
//        ])
        let chunk = ChunkModel(position: position, obstacles: [
            ObstacleModel(chunkPosition: position, points: [
                PointModel(x: 0, y: 0),
                PointModel(x: 25, y: 0),
                PointModel(x: 25, y: 25),
                PointModel(x: 0, y: 25)
            ]),
            ObstacleModel(chunkPosition: position, points: [
                PointModel(x: 75, y: 0),
                PointModel(x: 100, y: 0),
                PointModel(x: 100, y: 25),
                PointModel(x: 75, y: 25)
            ]),
            ObstacleModel(chunkPosition: position, points: [
                PointModel(x: 75, y: 75),
                PointModel(x: 100, y: 75),
                PointModel(x: 100, y: 100),
                PointModel(x: 75, y: 100)
            ]),
            ObstacleModel(chunkPosition: position, points: [
                PointModel(x: 0, y: 75),
                PointModel(x: 25, y: 75),
                PointModel(x: 25, y: 100),
                PointModel(x: 0, y: 100)
            ]),
        ])
        return chunk
    }
}
