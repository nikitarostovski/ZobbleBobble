//
//  CollisionCell.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

class CollisionCell {
    static let cellCapacity = 4
    static let maxCellIdx = cellCapacity - 1
    
    var objectCount = 0
    var objects = Set<Int>()
    
    func addAtom(_ id: Int) {
        objects.insert(id)
        objectCount += 1
    }
    
    func clear() {
        objectCount = 0
        objects.removeAll()
    }
    
    func remove(_ id: Int) {
        objects.remove(id)
        objectCount = objects.count
    }
}
