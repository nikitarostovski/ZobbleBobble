//
//  ChunkModel.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public struct ChunkModel: Codable {
    public let startImpulse: CGFloat
    public let particles: [ParticleModel]
    public let boundingRadius: CGFloat
}
