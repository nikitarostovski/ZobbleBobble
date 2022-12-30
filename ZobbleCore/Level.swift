//
//  Level.swift
//  LevelParser
//
//  Created by Rost on 14.11.2022.
//

import Foundation

public class Level {
    public struct Shape {
        public var position: CGPoint
        public var radius: Float
        public var color: CGRect
    }
    public let number: Int
    public let initialShapes: [Shape]
    public var playerShapes: [Shape]
    
    init(number: Int) {
        let shapes = Self.makeShapes(for: number)
        self.number = number
        self.initialShapes = shapes
        self.playerShapes = shapes
    }
    
    private static func makeShapes(for number: Int) -> [Shape] {
        let stepX: CGFloat = 400
        let stepY: CGFloat = 40
        
        return [
            CGPoint(x: stepX * CGFloat(number), y: stepY * CGFloat(number))
        ]
            .map { Shape(position: $0, radius: 20, color: CGRect(x: 255, y: 255, width: 255, height: 255)) }
    }
    
    public func addShape(position: CGPoint, radius: Float, color: CGRect) {
        playerShapes.append(Shape(position: position, radius: radius, color: color))
        print("\(number): \(playerShapes.count)")
    }
}
