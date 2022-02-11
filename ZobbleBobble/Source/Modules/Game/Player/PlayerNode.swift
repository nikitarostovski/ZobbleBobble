//
//  PlayerNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 27.12.2021.
//

import SpriteKit

final class PlayerNode: SKShapeNode {
    var weaponNode: WeaponNode? {
        didSet {
            oldValue?.removeFromParent()
            if let weaponNode = weaponNode {
                parent?.addChild(weaponNode)
            }
        }
    }
    
    static func make() -> PlayerNode {
        let p = PlayerNode(rectOf: CGSize(width: Const.planetRadius / 4, height: Const.planetRadius / 4), cornerRadius: 2)//(circleOfRadius: Const.playerRadius)
        p.fillColor = .red
        
        let body = SKPhysicsBody(circleOfRadius: Const.playerRadius)
        body.isDynamic = false
        body.friction = 100
        body.categoryBitMask = Category.unit.rawValue
        body.collisionBitMask = Category.terrain.rawValue
        
        p.physicsBody = body
        
        let positionUpdateInterval: CGFloat = 1.0 / 60.0
        let turnPerStep = 2 * .pi * Const.playerTurnsPerSecond * positionUpdateInterval
        Timer.scheduledTimer(withTimeInterval: positionUpdateInterval, repeats: true) { t in
            p.curAngle += turnPerStep
        }
        return p
    }
    
    private var curAngle: CGFloat = 0 {
        didSet {
            update()
        }
    }
    
    private func update() {
        let newX = cos(curAngle) * Const.planetRadius * Const.playerOrbitMultiplier
        let newY = sin(curAngle) * Const.planetRadius * Const.playerOrbitMultiplier
//        let newX = cos(-.pi / 2) * Const.planetRadius * Const.playerOrbitMultiplier
//        let newY = sin(-.pi / 2) * Const.planetRadius * Const.playerOrbitMultiplier
        position = CGPoint(x: newX, y: newY)
        zRotation = curAngle
        
        weaponNode?.zRotation = zRotation
        weaponNode?.position = position
    }
}
