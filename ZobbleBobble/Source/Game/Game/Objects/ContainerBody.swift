//
//  ContainerBody.swift
//  ZobbleBobble
//
//  Created by Rost on 24.08.2023.
//

import Foundation

class ContainerBody: Body {
    static let aspectRatio: CGFloat = 16/9
    
    var userInteractive: Bool = false
    
    private var actualRenderData: ContainerRenderData?
    
    var renderData: ContainerRenderData? {
        updateAppearanceIfNeeded()
        return actualRenderData
    }
    
    private let initialMaterials: [MaterialRenderData]
    private var needsUpdate = true
    
    private(set) var container: ContainerModel
    private(set) var visibleMaterials: [MaterialRenderData]
    
    var origin: CGPoint { didSet { if origin != oldValue { needsUpdate = true } } }
    var size: CGSize { didSet { if size != oldValue { needsUpdate = true } } }
    var mainColor: SIMD4<UInt8> { didSet { if mainColor != oldValue { needsUpdate = true } } }
    var missleOffset: CGFloat = 0 { didSet { if missleOffset != oldValue { needsUpdate = true } } }
    
    var center: CGPoint {
        get {
            return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        }
        set {
            origin = CGPoint(x: newValue.x - size.width / 2, y: newValue.y - size.height / 2)
        }
    }
    
    init(container: ContainerModel, frame: CGRect) {
        self.container = container
        self.origin = frame.origin
        self.size = frame.size
        self.mainColor = Colors.Container.mainColor
        
        var materials = [MaterialRenderData]()
        for (j, m) in container.missles.enumerated() {
            let j = container.missles.count - j - 1
            let number = CGFloat(j) / CGFloat(container.missles.count)
            let next = number + CGFloat(1) / CGFloat(container.missles.count)// - 0.01//CGFloat.leastNonzeroMagnitude
            var color = m.particles.first?.material.color ?? SIMD4<UInt8>(repeating: 0)//m.material.color
            color.w = 255;
            let material = MaterialRenderData(color: color, position: SIMD2(Float(number), Float(next)))
            materials.append(material)
        }
        self.initialMaterials = materials
        self.visibleMaterials = materials
        
        createRenderData()
    }
    
    private func updateAppearanceIfNeeded() {
        guard needsUpdate else { return }
        defer { needsUpdate = false }
        
        let offset = missleOffset / CGFloat(container.missles.count)
        
        let visibilityRange: ClosedRange<CGFloat> = 0...1
        
        visibleMaterials = initialMaterials.enumerated().compactMap { _, m in
            let start = offset + CGFloat(m.position.x)
            let end = offset + CGFloat(m.position.y)
            
            let color = m.color
            
            let convertedStart = (start - visibilityRange.lowerBound)// * materialScale / addScale
            let convertedEnd = (end - visibilityRange.lowerBound)// * materialScale / addScale
            
            if visibilityRange.contains(convertedStart) || visibilityRange.contains(convertedEnd) {
                return MaterialRenderData(color: color, position: SIMD2(Float(convertedStart), Float(convertedEnd)))
            }
            return nil
        }
        
        updateRenderData()
    }
    
    private func createRenderData() {
        let originPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                             alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        let sizePointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride,
                                                           alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        
        let materialsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<MaterialRenderData>.stride * Settings.Physics.maxMaterialCount,
                                                                alignment: MemoryLayout<MaterialRenderData>.alignment)
        self.actualRenderData = .init(originPointer: originPointer,
                                      sizePointer: sizePointer,
                                      materialsPointer: materialsPointer,
                                      materialCount: visibleMaterials.count)
    }
    
    private func updateRenderData() {
        guard let actualRenderData = actualRenderData else { return }
        
        var origin = SIMD2(Float(self.origin.x), Float(self.origin.y))
        var size = SIMD2(Float(self.size.width), Float(self.size.height))
        
        actualRenderData.originPointer.copyMemory(from: &origin, byteCount: MemoryLayout<SIMD2<Float32>>.stride)

        actualRenderData.sizePointer.copyMemory(from: &size, byteCount: MemoryLayout<SIMD2<Float32>>.stride)

        actualRenderData.materialsPointer.copyMemory(from: &self.visibleMaterials, byteCount: MemoryLayout<MaterialRenderData>.stride * visibleMaterials.count)

        self.actualRenderData?.materialCount = visibleMaterials.count
    }
}


