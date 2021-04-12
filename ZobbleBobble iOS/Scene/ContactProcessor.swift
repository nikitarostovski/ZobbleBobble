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
        
        if contact.collisionImpulse > 0.05 {
            if let wall = (contact.bodyA.node as? Wall) ?? (contact.bodyB.node as? Wall) {
                wall.explode(impulse: contact.collisionImpulse, normal: contact.contactNormal, contactPoint: contact.contactPoint)
            }
        }
    }
}
