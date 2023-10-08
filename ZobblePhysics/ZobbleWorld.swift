//
//  ZobbleWorld.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

public class ZobbleWorld {
    private let solver: ZobbleSolver
    
    public init(size: CGSize) {
        self.solver = .init(size: size)
    }
    
    private var renderDataPointer: UnsafeRawPointer?
    
    public var particleCount: Int {
        solver.objects.count
    }
    
    public var renderData: UnsafeRawPointer? {
        solver.objects.withUnsafeBytes { p in
            renderDataPointer = p.baseAddress
        }
        return renderDataPointer
    }
    
    public func step(_ time: CGFloat) {
        DispatchQueue.global().async {
//            autoreleasepool {
                self.solver.update(time)
//            }
        }
    }
    
    public func addParticle(_ pos: CGPoint, color: SIMD4<UInt8>) {
        let p = CGPoint(x: pos.x + solver.worldBounds.size.width / 2,
                        y: pos.y + solver.worldBounds.size.height / 2)
        solver.createObject(p, color)
    }
}
