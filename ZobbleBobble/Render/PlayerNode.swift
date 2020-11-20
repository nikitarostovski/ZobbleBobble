//
//  PlayerNode.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import SpriteKit

final class PlayerNode: SKNode, ObjectNode {
    
    var id: String?
    
    var node: SKShapeNode
    
    required init(object: PlayerModel) {
        self.id = object.id
        
        let radius = CGFloat(object.radius)
        
        node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = .blue
        
        super.init()
        
        addChild(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with object: Object?) {
        guard let object = object as? PlayerModel else { id = nil; return }
        
        self.position = CGPoint(x: CGFloat(object.position.x), y: CGFloat(object.position.y))
//        self.zRotation = object.
    }
}
