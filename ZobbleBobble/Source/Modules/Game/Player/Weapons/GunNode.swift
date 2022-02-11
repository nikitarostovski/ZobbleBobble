//
//  GunNode.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 22.01.2022.
//

import SpriteKit

final class GunNode: SKNode, WeaponNode {
    static func make() -> WeaponNode {
        let node = GunNode()
        
        let fireUpdateInterval: CGFloat = 1.0 / 60.0
        let shotInterval = 1.0 / 12//Const.playerShotsPerSecond
        var timeSinceLastFire: TimeInterval = 0
        Timer.scheduledTimer(withTimeInterval: fireUpdateInterval, repeats: true) { t in
            timeSinceLastFire += fireUpdateInterval
            guard node.fireIsOn else { return }
            
            if timeSinceLastFire >= shotInterval {
                node.fire()
                timeSinceLastFire = 0
            }
        }
        
        return node
    }
    
    private var fireIsOn = false
    
    func startFire() {
        fireIsOn = true
    }
    
    func stopFire() {
        fireIsOn = false
    }
    
    private func fire() {
        let missle = BulletNode.make()
        missle.position = position
        scene?.addChild(missle)
        
        let angle = position.angle(to: .zero).radians
        let force: CGFloat = 0.5
        let impulse = CGVector(dx: force * cos(angle),
                               dy: force * sin(angle))
        missle.physicsBody?.applyImpulse(impulse)
    }
}