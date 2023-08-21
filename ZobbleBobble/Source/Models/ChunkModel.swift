//
//  ChunkModel.swift
//  ZobbleBobble
//
//  Created by Rost on 21.08.2023.
//

import Foundation

public struct ChunkModel: Codable {
    public var startImpulse: CGFloat
    public var particles: [ParticleModel]
    public var boundingRadius: CGFloat
}
