//
//  Cell.swift
//  ZobbleBobble
//
//  Created by Никита Ростовский on 12.04.2021.
//

import CoreGraphics

struct Cell: Codable {
    
    struct Color: Codable {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        
        static var random: Color {
            let r = CGFloat(arc4random() % 255)
            let g = CGFloat(arc4random() % 255)
            let b = CGFloat(arc4random() % 255)
            return Color(r: r / 255, g: g / 255, b: b / 255)
        }
    }
    
    var center: CGPoint
    var polygon: Polygon
    var color: Color
    
    init(center: CGPoint) {
        self.center = center
        self.polygon = []
        self.color = Color.random
    }
}
