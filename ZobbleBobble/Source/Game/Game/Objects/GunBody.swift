//
//  GunBody.swift
//  ZobbleBobble
//
//  Created by Rost on 24.08.2023.
//

import Foundation

class GunBody: Body {
    var userInteractive: Bool { false }
    
    private var needsUpdate = true
    private var actualRenderData: GunRenderData?

    weak var player: PlayerModel?
    weak var containerBody: ContainerBody?
    
    var origin: CGPoint { didSet { if origin != oldValue { needsUpdate = true } } }
    var size: CGSize { didSet { if size != oldValue { needsUpdate = true } } }
    var mainColor: SIMD4<UInt8> { didSet { if mainColor != oldValue { needsUpdate = true } } }
    var currentMissleIndex: CGFloat = 0 { didSet { if currentMissleIndex != oldValue { needsUpdate = true } } }

    var renderData: GunRenderData? {
        updateAppearanceIfNeeded()
        return actualRenderData
    }
    
    var center: CGPoint {
        get {
            return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        }
        set {
            origin = CGPoint(x: newValue.x - size.width / 2, y: newValue.y - size.height / 2)
        }
    }
    
    var selectedContainer: ContainerModel? { player?.selectedContainer }

    var selectedMissle: ChunkModel? {
        let index = Int(currentMissleIndex)
        guard let selectedContainer = selectedContainer, 0..<selectedContainer.missles.count ~= index else { return nil }
        return selectedContainer.missles[index]
    }
    
    init(player: PlayerModel?, container: ContainerBody?, frame: CGRect) {
        self.player = player
        self.containerBody = container
        self.origin = frame.origin
        self.size = frame.size
        self.mainColor = Colors.Container.mainColor
        
        createRenderData()
    }
    
    private func updateAppearanceIfNeeded() {
        guard needsUpdate else { return }
        defer { needsUpdate = false }
        
        containerBody?.missleOffset = currentMissleIndex
        updateRenderData()
    }
    
    private func createRenderData() {
        let originPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                               alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let sizePointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                                   alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        self.actualRenderData = .init(originPointer: originPointer,
                                      sizePointer: sizePointer)
    }
    
    private func updateRenderData() {
        guard let actualRenderData = actualRenderData else { return }
        
        var origin = SIMD2(Float(origin.x), Float(origin.y))
        var size = SIMD2(Float(size.width), Float(size.height))
        
        actualRenderData.originPointer.copyMemory(from: &origin, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
        
        actualRenderData.sizePointer.copyMemory(from: &size, byteCount: MemoryLayout<SIMD2<Float32>>.stride)
    }
}

extension GunBody: MissleHolder {
    func getMissleCenter() -> SIMD2<Float32> {
        let missleIndex = Int(currentMissleIndex)
        let missleRadius = containerBody?.container.missles[missleIndex].boundingRadius ?? 0
        return .init(Float32(center.x), Float32(origin.y - missleRadius))
    }

    func getInitialPositions(particleCount: Int) -> [SIMD2<Float32>] {
        guard let containerBody = containerBody else { return [] }
        
        let left = containerBody.origin.x
        let right = containerBody.origin.x + containerBody.size.width
        let top = containerBody.origin.y
        let bottom = containerBody.origin.y
        return (0..<particleCount).map { _ in
            SIMD2<Float>(Float.random(in: Float(left)...Float(right)),
                         Float.random(in: Float(top)...Float(bottom)))
            
        }
    }
}
