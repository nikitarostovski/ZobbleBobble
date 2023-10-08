//
//  ZobbleSolver.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation
import Dispatch

@propertyWrapper public struct ThreadSafe<T> {
    private var _value: T
    private let lock = NSLock()
    private let queue: DispatchQueue

    public var wrappedValue: T {
        get {
            queue.sync { _value }
        }
        _modify {
            lock.lock()
            var tmp: T = _value

            defer {
                _value = tmp
                lock.unlock()
            }

            yield &tmp
        }
    }

    public init(wrappedValue: T, queue: DispatchQueue? = nil) {
        self._value = wrappedValue
        self.queue = queue ?? DispatchQueue(label: "ThreadSafe \(String(typeName: T.self))")
    }
}

// Helper extension to name the queue after the property wrapper's type.
public extension String {
    init(typeName thing: Any.Type) {
        let describingString = String(describing: thing)
        let name = describingString.components(separatedBy: ".").last ?? ""

        self.init(stringLiteral: name)
    }
}

@propertyWrapper struct Atomic<Value> {
    private typealias os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>
    private var lock: os_unfair_lock_t
    var value: Value

    init(wrappedValue: Value) {
        self.value = wrappedValue

        var lock: os_unfair_lock_t
        lock = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        self.lock = lock
    }

    var wrappedValue: Value {
        get {
            os_unfair_lock_lock(lock)
            let result = value
            os_unfair_lock_unlock(lock)
            return result
        }
        set {
            os_unfair_lock_lock(lock)
            value = newValue
            os_unfair_lock_unlock(lock)
        }
    }
}


class ZobbleSolver {
    private let queue = DispatchQueue(label: "ZobbblePhysics.solver")//, attributes: .concurrent)
    
    private let gravity: CGPoint = .init(x: -5, y: -20)
    
    private var _objects = ContiguousArray<ZobbleBody>()
    var objects: ContiguousArray<ZobbleBody> {
        get {
            return queue.sync(flags: .barrier, execute: {
                return _objects
            })
        }
        set {
            queue.sync(flags: .barrier, execute: {
                self._objects = newValue
            })
        }
    }
    
    private var grid: CollisionGrid
    let worldBounds: CGRect
    
    // Simulation solving pass count
    private let subSteps = 8
    private let threadPool: ThreadPool
    
    init(size: CGSize) {
        self.worldBounds = .init(origin: .zero, size: size)
        self.grid = CollisionGrid(width: Int(size.width), height: Int(size.height))
        self.threadPool = PThreadPool(threadCount: 8)
//        self.threadPool = DispatchPool(threadCount: 12)
        grid.clear()
    }
    
    func update(_ dt: CGFloat) {
//        let clock = ParkBenchTimer()
        
        // Perform the sub steps
        let subDt = dt / CGFloat(subSteps)
        for _ in (0..<subSteps) {
            addObjectsToGrid()
            solveCollisions()
            updateObjectsMulti(subDt)
        }
        
//        print("[Physics] Bodies: \(objects.count), time elapsed: \(Int(clock.stop() * 1000))ms")
    }
    
    /// Add a new object to the solver
    func createObject(_ pos: CGPoint, _ color: SIMD4<UInt8>) {
        let obj = ZobbleBody(position: pos, acceleration: .zero, color: color)
        objects.append(obj)
    }

    /// Checks if two atoms are colliding and if so create a new contact
    private func solveContact(_ atom1Idx: Int, _ atom2Idx: Int) {
        let respCoef: CGFloat = 1
        let eps: CGFloat = 0.0001
        
        var obj1 = objects[atom1Idx]
        var obj2 = objects[atom2Idx]
        let o2_o1 = obj1.position.pointValue - obj2.position.pointValue
        let dist2 = o2_o1.x * o2_o1.x + o2_o1.y * o2_o1.y
        
        if dist2 < 1, dist2 > eps {
            let dist = sqrt(dist2)
            // Radius are all equal to 1.0f
            let delta = respCoef * 0.5 * (1 - dist)
            let colVec = (o2_o1 / dist) * delta
            obj1.position += colVec.simdValue
            obj2.position -= colVec.simdValue
            
            objects[atom1Idx] = obj1
            objects[atom2Idx] = obj2
        }
    }

    private func checkAtomCellCollisions(_ atomIdx: Int, _ c: CollisionCell?) {
        guard let c = c else { return }
        for obj in c.objects {
            solveContact(atomIdx, obj)
        }
    }

    private func processCell(_ c: CollisionCell, _ index: Int) {
        for atomIdx in c.objects {
            let indices = [
                index - 1,
                index,
                index + 1,
                index + grid.height - 1,
                index + grid.height,
                index + grid.height + 1,
                index - grid.height - 1,
                index - grid.height,
                index - grid.height + 1
            ]
            for index in indices {
                grid.getCell(at: index) { [weak self] cell in
                    self?.checkAtomCellCollisions(atomIdx, cell)
                }
            }
        }
    }

    private func solveCollisionThreaded(_ i: Int, _ sliceSize: Int) {
        let start = i * sliceSize
        let end = (i + 1) * sliceSize
        
        for idx in start..<end {
            grid.getCell(at: idx) { [weak self] cell in
                guard let cell = cell, let self = self else { return }
                self.processCell(cell, idx)
            }
        }
    }

    /// Find colliding atoms
    private func solveCollisions() {
        // Multi-thread grid
        let threadCount = threadPool.threadCount
        let sliceCount = 2 * threadCount
        let sliceSize = (grid.width / sliceCount) * grid.height
        
        // Find collisions in two passes to avoid data races
        // First collision pass
        
        for i in 0..<threadCount {
            threadPool.addTask { [weak self] in
                self?.solveCollisionThreaded(2 * i, sliceSize);
            }
        }
        threadPool.waitForCompletion()
        
        // Second collision pass
        for i in 0..<threadCount {
            threadPool.addTask { [weak self] in
                self?.solveCollisionThreaded(2 * i + 1, sliceSize)
            }
        }
        threadPool.waitForCompletion()
    }

    /// Add a new object to the solver
    private func addObject(_ object: ZobbleBody) {
        objects.append(object)
    }

    private func addObjectsToGrid() {
        grid.clear()
        // Safety border to avoid adding object outside the grid
        var i = 0
        
        for obj in objects {
            let pos = obj.position.pointValue
            
            let left = worldBounds.origin.x + 1
            let right = worldBounds.origin.x + worldBounds.size.width - 1
            let top = worldBounds.origin.y + 1
            let bottom = worldBounds.origin.y + worldBounds.size.height - 1
            
            if (pos.x > left && pos.x < right &&
                pos.y > top && pos.y < bottom) {
                grid.addAtom(Int(pos.x), Int(pos.y), i)
            }
            i += 1
        }
    }

    func updateObjectsMulti(_ dt: CGFloat) {
        threadPool.dispatch(objects.count) { [weak self] start, end in
            guard let self = self else { return }
            for i in start..<end {
                var obj = objects[i]
                // Add gravity
                obj.acceleration += gravity.simdValue
                // Apply Verlet integration
                obj.update(dt)
                // Apply map borders collisions
                let margin: Float = 2
                
                let left = Float(worldBounds.origin.x) + margin
                let right = Float(worldBounds.origin.x + worldBounds.size.width) - margin
                let top = Float(worldBounds.origin.y) + margin
                let bottom = Float(worldBounds.origin.y + worldBounds.size.height) - margin
                
                if (obj.position.x > right) {
                    obj.position.x = right
                } else if (obj.position.x < left) {
                    obj.position.x = left
                }
                if (obj.position.y > bottom) {
                    obj.position.y = bottom
                } else if (obj.position.y < top) {
                    obj.position.y = top
                }
                objects[i] = obj
            }
        }
    }
}

class ParkBenchTimer {
    let startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()

        return duration!
    }

    var duration: CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}
