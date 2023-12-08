//
//  ZobbleBody.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

public struct ZobbleBody {
    var lastPosition: SIMD2<Float>
    var position: SIMD2<Float> {
        didSet {
            lastPosition = oldValue
        }
    }
    var acceleration: SIMD2<Float>
    var color: SIMD4<UInt8>
    
    init(position: CGPoint, acceleration: CGPoint, color: SIMD4<UInt8>) {
        self.position = position.simdValue
        self.lastPosition = position.simdValue
        self.acceleration = acceleration.simdValue
        self.color = color
    }
    
    mutating func update(_ dt: CGFloat) {
        let lastUpdateMove = position - lastPosition
        let newX = position.x + lastUpdateMove.x + (acceleration.x - lastUpdateMove.x * 40) * Float(dt * dt)
        let newY = position.y + lastUpdateMove.y + (acceleration.y - lastUpdateMove.y * 40) * Float(dt * dt)
        
        lastPosition = position
        position = .init(newX, newY)
        acceleration = .zero
    }
    
    mutating func stop() {
        lastPosition = position
    }
    
    mutating func slowdown(_ ratio: CGFloat) {
        lastPosition = lastPosition + Float(ratio) * (position - lastPosition)
    }
    
    func getSpeed() -> Float {
        (position - lastPosition).length
    }
    
    func getVelocity() -> CGPoint {
        (position - lastPosition).pointValue
    }
    
    mutating func addVelocity(_ v: CGPoint) {
        lastPosition -= v.simdValue
    }
    
    mutating func setPositionSameSpeed(_ newPosition: CGPoint) {
        let toLast = lastPosition - position
        position = newPosition.simdValue
        lastPosition = position + toLast
    }
    
    mutating func move(_ v: CGPoint) {
        position += v.simdValue
    }
}

extension CGPoint {
    var simdValue: SIMD2<Float> {
        .init(Float(x), Float(y))
    }
}

extension SIMD2<Float> {
    var pointValue: CGPoint {
        .init(x: CGFloat(x), y: CGFloat(y))
    }
    
    var length: Float {
        Float(pointValue.length)
    }
}
