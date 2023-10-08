//
//  CollisionGrid.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

class CollisionGrid: Grid<CollisionCell> {
    private typealias os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>
    private var lock: os_unfair_lock_t

    override init(width: Int, height: Int) {
        var lock: os_unfair_lock_t
        lock = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        lock.initialize(to: .init())
        self.lock = lock
        
        super.init(width: width, height: height)
        for i in 0..<(width * height) {
            self.data[i] = CollisionCell()
        }
    }
    
    func getCell(at: Int, _ completion: @escaping (_ cell: CollisionCell?) -> Void) {
        os_unfair_lock_lock(lock)
        completion(self.data[at])
        os_unfair_lock_unlock(lock)
    }
    
    func addAtom(_ x: Int, _ y: Int, _ atom: Int) {
        os_unfair_lock_lock(lock)
        let id = x * self.height + y
        let cell = self.data[id] ?? CollisionCell()
        cell.addAtom(atom)
        self.data[id] = cell
        os_unfair_lock_unlock(lock)
    }
    
    func clear() {
        os_unfair_lock_lock(lock)
        for c in self.data.values {
            c.objectCount = 0
        }
        os_unfair_lock_unlock(lock)
    }
}

class Grid<T: AnyObject> {
    var width: Int
    var height: Int
    
    fileprivate var data: [Int: T] = [:]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    func get(_ v: CGPoint) -> T? {
        get(Int(v.x), Int(v.y))
    }
    
    func get(_ x: Int, _ y: Int) -> T? {
        data[y * width + x]
    }

    func set(_ v: CGPoint, _ obj: T?) {
        set(Int(v.x), y: Int(v.y), obj: obj)
    }
    
    func set(_ x: Int, y: Int, obj: T?) {
        data[y * width + x] = obj
    }
}
