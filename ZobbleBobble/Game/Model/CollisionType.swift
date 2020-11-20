//
//  CollisionType.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 14.11.2020.
//

import Foundation

enum CollisionType: UInt16 {
    case player = 0x0001
    case obstacle = 0x0002
    case water = 0x0004
}
