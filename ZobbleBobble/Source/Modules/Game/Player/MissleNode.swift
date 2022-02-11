//
//  MissleNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit

protocol MissleNode: SKShapeNode {
    static func make() -> MissleNode
    
    func processHit(with chunk: ChunkNode, terrain: TerrainNode, impulse: CGFloat, normal: CGVector, contactPoint: CGPoint)
}
