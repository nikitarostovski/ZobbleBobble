//
//  Level.swift
//  LevelDesign
//
//  Created by Rost on 17.03.2021.
//

import Foundation

typealias Polygon = [CGPoint]

class Level {
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var polygons = [Polygon]() {
        didSet {
            updateSize()
        }
    }
    
    init(polygons: [Polygon] = []) {
        self.polygons = polygons
        updateSize()
    }
    
    private func updateSize() {
        var w: CGFloat = 0
        var h: CGFloat = 0
        
        self.polygons.forEach {
            w = max(w, $0.max(by: { $0.x > $1.x })?.x ?? 0)
            h = max(h, $0.max(by: { $0.y > $1.y })?.y ?? 0)
        }
        
        self.width = w + 1
        self.height = h + 1
    }
}
