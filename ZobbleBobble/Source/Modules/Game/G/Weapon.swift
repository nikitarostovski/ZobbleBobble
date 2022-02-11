//
//  Weapon.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 09.02.2022.
//

import SpriteKit

enum WeaponType: String, CaseIterable {
    case gun
    case rocket
    case nuke
    case plasma
    case laser
}

class Weapon: SKShapeNode {
    private let height: CGFloat = 12
    
    let world: World
    let type: WeaponType
    
    init(world: World, type: WeaponType) {
        self.world = world
        self.type = type
        super.init()
        
        self.path = CGPath(rect: CGRect(x: -1, y: 0, width: 2, height: height), transform: nil)
        self.position = CGPoint(x: world.player.position.x + world.player.weaponAnchor.x,
                                y: world.player.position.y + world.player.weaponAnchor.y)
        
        self.strokeColor = .clear
        switch type {
        case .gun:
            self.fillColor = .yellow
        case .rocket:
            self.fillColor = .brown
        case .nuke:
            self.fillColor = .orange
        case .plasma:
            self.fillColor = .green
        case .laser:
            self.fillColor = .red
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fire() {
        let center = CGPoint(x: position.x, y: position.y + height)
        
        let missleType: MissleType
        switch type {
        case .gun, .plasma, .laser:
            missleType = .bullet
        case .rocket:
            missleType = .rocket
        case .nuke:
            missleType = .nuke
        }
        let missle = Missle(world: world, type: missleType, position: center)
        world.addChild(missle)
        
        let angle = center.angle(to: .zero).radians
        let force: CGFloat = 20
        let impulse = CGVector(dx: force * cos(angle),
                               dy: force * sin(angle))
        missle.physicsBody?.applyImpulse(impulse)
    }
}
