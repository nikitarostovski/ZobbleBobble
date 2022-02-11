//
//  Player.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 29.01.2022.
//

import SpriteKit

final class Player: SKShapeNode {
    private let radius: CGFloat = 5
    
    let world: World
    var weapon: Weapon? {
        didSet {
            oldValue?.removeFromParent()
            if let weapon = weapon {
                world.addChild(weapon)
            }
        }
    }
    
    var weaponAnchor: CGPoint {
        CGPoint(x: 0, y: radius)
    }
    
    init(world: World, position: CGPoint) {
        self.world = world
        super.init()
        self.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius), transform: nil)
        self.position = position
        self.fillColor = .white
        self.strokeColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fire() {
        weapon?.fire()
    }
}
