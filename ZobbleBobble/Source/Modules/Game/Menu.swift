//
//  Menu.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation
import ZobbleCore

final class Menu {
    private let levels: [Level]
    
    var circleBodyCount: Int?
    var circleBodiesPositions: UnsafeMutableRawPointer?
    var circleBodiesColors: UnsafeMutableRawPointer?
    var circleBodiesRadii: UnsafeMutableRawPointer?
    
    var backgroundAnchorPointCount: Int? { nil }
    var backgroundAnchorPoints: UnsafeMutableRawPointer? { nil }
    var backgroundAnchorRadii: UnsafeMutableRawPointer? { nil }
    
    init(levels: [Level]) {
        self.levels = levels
        updateData()
    }
    
    private func updateData() {
        let allShapes = levels.flatMap { $0.playerShapes }
        var allPositions: [SIMD2<Float32>] = allShapes.map { SIMD2<Float32>(Float32($0.position.x), Float32($0.position.y)) }
        var allRadii: [Float] = allShapes.map { $0.radius }
        var allColors: [SIMD4<UInt8>] = allShapes.map { $0.color.simdColor }
        
        let positions = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count, alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        positions.copyMemory(from: &allPositions, byteCount: MemoryLayout<SIMD2<Float32>>.stride * allPositions.count)
        
        let radii = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.stride * allRadii.count, alignment: MemoryLayout<Float>.alignment)
        radii.copyMemory(from: &allRadii, byteCount: MemoryLayout<Float>.stride * allRadii.count)
        
        let colors = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count, alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        colors.copyMemory(from: &allColors, byteCount: MemoryLayout<SIMD4<UInt8>>.stride * allColors.count)
        
        self.circleBodiesPositions = positions
        self.circleBodiesRadii = radii
        self.circleBodiesColors = colors
        self.circleBodyCount = allShapes.count
    }
}

extension Menu: RenderDataSource {
    var backgroundAnchorPositions: UnsafeMutableRawPointer? {
        nil
    }
    
    var backgroundAnchorColors: UnsafeMutableRawPointer? {
        nil
    }
    
    var particleRadius: Float {
        0
    }
    
    var liquidCount: Int? {
        0
    }
    
    var liquidPositions: UnsafeMutableRawPointer? {
        nil
    }
    
    var liquidVelocities: UnsafeMutableRawPointer? {
        nil
    }
    
    var liquidColors: UnsafeMutableRawPointer? {
        nil
    }
}
