//
//  Terrain.swift
//  ZobbleBobble iOS
//
//  Created by Rost on 14.02.2021.
//

import SpriteKit

class Terrain: SKNode {
    
//    var bounds: CGRect
    
    var walls: [Wall]
    
    init(polygons: [Polygon]) {
        var walls = [Wall]()
        polygons.indices.forEach { i in
            var p = polygons[i]
            p.append(p.first!)
            let wall = Wall.make(from: &p)
            walls.append(wall)
        }
        self.walls = walls
        
//        self.bounds = CGRect(origin: .zero, size: size)
        
        
        super.init()
        
        walls.forEach { $0.terrain = self; addChild($0) }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func replace(wall: Wall, with walls: [Wall]) {
        wall.destroy()
        self.walls.removeAll(where: { $0 === wall })
        self.walls.append(contentsOf: walls)

        walls.forEach { $0.terrain = self; addChild($0) }
    }
}
