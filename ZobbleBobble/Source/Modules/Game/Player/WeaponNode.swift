//
//  WeaponNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 18.01.2022.
//

import SpriteKit

protocol WeaponNode: SKNode {
    static func make() -> WeaponNode
    
    func startFire()
    func stopFire()
}
