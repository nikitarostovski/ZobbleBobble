//
//  GameScene+Contacts.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 15.11.2020.
//

import SpriteKit

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == CollisionType.player.rawValue || contact.bodyB.categoryBitMask == CollisionType.player.rawValue,
           contact.bodyA.categoryBitMask == CollisionType.water.rawValue || contact.bodyB.categoryBitMask == CollisionType.water.rawValue {
            
            print("GAME OVER")
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        
    }
}
