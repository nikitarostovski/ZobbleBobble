//
//  GameScene+Touches.swift
//  ZobbleBobble
//
//  Created by Nikita Rostovskii on 15.11.2020.
//

import SpriteKit
import Box2D

extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startTouchLocation = touches.first?.location(in: self)
        
        trajectory?.showTrajectory()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let startTouchLocation = startTouchLocation,
              let curTouchLocation = touches.first?.location(in: self)
        else { return }
        
        let vector = makeImpulse(start: startTouchLocation, end: curTouchLocation)
        trajectory?.impulse = b2Vec2(cgVector: vector)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let startTouchLocation = startTouchLocation,
              let endTouchLocation = touches.first?.location(in: self)
        else { return }
        
        trajectory?.hideTrajectory()
        
        self.startTouchLocation = nil
        
        let vector = makeImpulse(start: startTouchLocation, end: endTouchLocation)
        player.applyImpulse(vector)
        
        trajectory?.impulse = b2Vec2(cgVector: vector)
    }
    
    private func makeImpulse(start: CGPoint, end: CGPoint) -> CGVector {
        let distance = end.distance(to: start)
        let angle = end.angle(to: start)
        
        let normX = cos(angle)
        let normY = sin(angle)
        
        let power = distance * 10000
        
        let vector = CGVector(dx: power * normX, dy: power * normY)
        return vector
    }
}
