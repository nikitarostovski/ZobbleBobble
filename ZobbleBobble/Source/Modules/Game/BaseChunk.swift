//
//  BaseChunk.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 28.01.2022.
//

import SpriteKit

protocol BaseChunk {
    var material: Material { get }
    var hp: Float { get set }
}

