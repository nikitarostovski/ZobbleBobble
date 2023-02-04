//
//  Background.swift
//  ZobbleBobble
//
//  Created by Rost on 28.01.2023.
//

import Foundation

final class Background: BackgroundRenderDataSource {
    var backgroundAnchorPositions: UnsafeMutableRawPointer?
    var backgroundAnchorRadii: UnsafeMutableRawPointer?
    var backgroundAnchorColors: UnsafeMutableRawPointer?
    var backgroundAnchorPointCount: Int?
    
    private weak var game: Game?
    weak var objectPositionProvider: ObjectPositionProvider?
    
    init(game: Game) {
        self.game = game
    }
    
    func updateRenderData() {
        guard let game = game, let objectPositionProvider = objectPositionProvider else { return }
        
        let packs = game.levelManager.allLevelPacks[objectPositionProvider.visibleLevelPackIndices]
        
        var outlinePositions = [SIMD2<Float32>]()
        var outlineColors = [SIMD4<UInt8>]()
        var outlineRadii = [Float]()
        
//        for pack in packs {
//            guard let pos = objectPositionProvider.convertStarPosition(pack.number),
//                  let r = objectPositionProvider.convertStarRadius(pack.targetOutline.radius)
//            else { return }
//            
//            outlinePositions.append(SIMD2<Float32>(Float32(pos.x), Float32(pos.y)))
//            outlineRadii.append(Float(r * 1.25))
//            outlineColors.append(pack.targetOutline.color)
//        }
        
//        let levels = game.levelManager.allLevelPacks[game.state.packIndex].levels[objectPositionProvider.visibleLevelIndices]
//
//        for level in levels {
//            guard let pos = objectPositionProvider.convertPlanetPosition(level.number),
//                    let r = objectPositionProvider.convertPlanetRadius(level.targetOutline.radius)
//            else { return }
//
//            outlinePositions.append(SIMD2<Float32>(Float32(pos.x), Float32(pos.y)))
//            outlineRadii.append(Float(r))
//            outlineColors.append(level.targetOutline.color)
//        }

        let outlinePositionsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count, alignment: MemoryLayout<SIMD2<Float32>>.alignment)
        outlinePositionsPointer.copyMemory(from: &outlinePositions, byteCount: MemoryLayout<SIMD2<Float32>>.stride * outlinePositions.count)

        let outlineRadiiPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Float>.stride * outlineRadii.count, alignment: MemoryLayout<Float>.alignment)
        outlineRadiiPointer.copyMemory(from: &outlineRadii, byteCount: MemoryLayout<Float>.stride * outlineRadii.count)

        let outlineColorsPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count, alignment: MemoryLayout<SIMD4<UInt8>>.alignment)
        outlineColorsPointer.copyMemory(from: &outlineColors, byteCount: MemoryLayout<SIMD4<UInt8>>.stride * outlineColors.count)

        self.backgroundAnchorPositions = outlinePositionsPointer
        self.backgroundAnchorRadii = outlineRadiiPointer
        self.backgroundAnchorColors = outlineColorsPointer
        self.backgroundAnchorPointCount = outlinePositions.count
    }
}
