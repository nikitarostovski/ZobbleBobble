//
//  ContactProcessor.swift
//  ZobbleBobble iOS
//
//  Created by Никита Ростовский on 11.04.2021.
//

import SpriteKit

class ContactProcessor: NSObject, SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
//        print(contact.collisionImpulse)
        
        guard let wall = (contact.bodyA.node as? Wall) ?? (contact.bodyB.node as? Wall),
              let missle = (contact.bodyA.node as? Missle) ?? (contact.bodyB.node as? Missle)
        else {
            return
        }
        
        missle.explode()
        
        if contact.collisionImpulse > 0.02 {
            wall.explode(impulse: contact.collisionImpulse, normal: contact.contactNormal, contactPoint: contact.contactPoint)
        }
    }
}
