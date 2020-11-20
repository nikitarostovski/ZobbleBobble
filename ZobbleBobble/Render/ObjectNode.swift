//
//  ObjectNode.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import SpriteKit

protocol ObjectNode where Self: SKNode {
    
    var id: String? { get }
    
    func update(with object: Object?)
}
