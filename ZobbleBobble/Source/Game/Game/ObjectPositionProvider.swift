//
//  ObjectPositionProvider.swift
//  ZobbleBobble
//
//  Created by Rost on 28.01.2023.
//

import Foundation

protocol ObjectPositionProvider: AnyObject {
    var visibleLevelPackIndices: ClosedRange<Int> { get }
    var visibleLevelIndices: ClosedRange<Int> { get }
    
    func convertStarPosition(_ index: Int) -> CGPoint?
    func convertStarRadius(_ radius: CGFloat) -> CGFloat?
    func convertPlanetPosition(_ index: Int) -> CGPoint?
    func convertPlanetRadius(_ radius: CGFloat) -> CGFloat?
}

extension ObjectPositionProvider {
    var visibleLevelPackIndices: ClosedRange<Int> { 0...0 }
    var visibleLevelIndices: ClosedRange<Int> { 0...0 }
}
