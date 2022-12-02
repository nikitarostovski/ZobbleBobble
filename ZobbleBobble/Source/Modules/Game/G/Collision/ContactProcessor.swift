//
//  ContactProcessor.swift
//  ZobbleBobble iOS
//
//  Created by Никита Ростовский on 11.04.2021.
//

import SpriteKit

final class ContactProcessor: NSObject {
//    weak var terrain: TerrainNode?
    
//    private func processHit(missle: MissleNode, chunk: ChunkNode, impulse: CGFloat, normal: CGVector, contactPoint: CGPoint) {
//        guard let terrain = terrain else { return }
//        terrain.chunks.forEach { $0.updateModel() }
//
//        missle.processHit(with: chunk, terrain: terrain, impulse: impulse, normal: normal, contactPoint: contactPoint)
//    }
}

extension ContactProcessor: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
//        guard let missle = (contact.bodyA.node as? Missle) ?? (contact.bodyB.node as? Missle) else { return }
//        missle.processCollision(at: contact.contactPoint, impulse: contact.collisionImpulse)
        
        
        
//        switch missle.type {
//        case .bullet, .rocket:
//            
//            
//        }
//        processHit(missle: missle, chunk: chunk, impulse: contact.collisionImpulse, normal: contact.contactNormal, contactPoint: contact.contactPoint)
    }
}
