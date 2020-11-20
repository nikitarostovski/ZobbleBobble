//
//  ObstacleNode.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 18.11.2020.
//

import SpriteKit

final class ObstacleNode: SKNode, ObjectNode {
    
    var id: String?
    
    var node: SKShapeNode
    
    required init(object: ObstacleModel) {
        self.id = object.id
        
        var points = object.points.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        node = SKShapeNode(points: &points, count: points.count)
        node.fillColor = .red
        
        super.init()
        
        addChild(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with object: Object?) {
        guard let object = object as? ObstacleModel else { id = nil; return }
        self.position = CGPoint(x: CGFloat(object.position.x), y: CGFloat(object.position.y))
    }
}
