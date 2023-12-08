//
//  ZobbleWorld.swift
//  ZobblePhysics
//
//  Created by Никита Ростовский on 03.10.2023.
//

import Foundation

public protocol ZobbleWorldDelegate: AnyObject {
    func worldDidUpdate(withParticles particles: UnsafeRawPointer?, count particleCount: Int32)
}

public class ZobbleWorld {
    private let solver: ZobbleSolver
    private var renderDataPointer: UnsafeRawPointer?
    
    public weak var delegate: ZobbleWorldDelegate?
    
    var particleCount: Int {
        solver.objects.count
    }
    
    var renderData: UnsafeRawPointer? {
        solver.objects.withUnsafeBytes { p in
            renderDataPointer = p.baseAddress
        }
        return renderDataPointer
    }
    
    public init(size: CGSize) {
        self.solver = .init(size: size)
        
        Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            let time = timer.timeInterval
            solver.update(time)
            
            var particles: UnsafeRawPointer?
            let count = solver.objects.count
            solver.objects.withUnsafeBytes { p in
                particles = p.baseAddress
            }
            delegate?.worldDidUpdate(withParticles: particles, count: Int32(count))
        }
    }
    
    public func addParticle(withPos pos: CGPoint, color: SIMD4<UInt8>) {
        let p = CGPoint(x: pos.x + solver.worldBounds.size.width / 2,
                        y: pos.y + solver.worldBounds.size.height / 2)
        solver.createObject(p, color)
    }
}
