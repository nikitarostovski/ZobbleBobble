//
//  Object.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import Foundation
import Box2D

enum ObjectType {
    case player
    case obstacle
}

protocol Object {
    
    var id: String { get }
    var `type`: ObjectType { get }
    
    var body: b2Body? { get set }
    
    func makeBody(world: b2World)
    func update()
}
