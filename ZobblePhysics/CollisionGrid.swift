//
//  CollisionGrid.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

class CollisionGrid: Grid<CollisionCell> {
    override init(width: Int, height: Int) {
        super.init(width: width, height: height)
        for i in 0..<(width * height) {
            set(i, obj: CollisionCell())
        }
    }
    
    func addAtom(_ x: Int, _ y: Int, _ atom: Int) {
        let cell = get(x, y) ?? CollisionCell()
        cell.addAtom(atom)
        
        set(x, y: y, obj: cell)
    }
    
    func clear() {
        mapAll {
            $0.objectCount = 0
        }
    }
}

class Grid<T: AnyObject> {
    var width: Int
    var height: Int
    
    private var data: [Int: T] = [:]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    func get(_ v: CGPoint) -> T? {
        get(Int(v.x), Int(v.y))
    }
    
    func get(_ x: Int, _ y: Int) -> T? {
        get(y * width + x)
    }
    
    func get(_ i: Int) -> T? {
        data[i]
    }

    func set(_ v: CGPoint, _ obj: T?) {
        set(Int(v.x), y: Int(v.y), obj: obj)
    }
    
    func set(_ x: Int, y: Int, obj: T?) {
        set(y * width + x, obj: obj)
    }
    
    func set(_ i: Int, obj: T?) {
        data[i] = obj
    }
    
    func mapAll(_ closure: (T) -> Void) {
        _ = data.values.map(closure)
    }
}
