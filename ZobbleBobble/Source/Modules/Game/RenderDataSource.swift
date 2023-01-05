//
//  RenderDataSource.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation

protocol RenderDataSource: AnyObject {
    var particleRadius: Float { get }
    var liquidCount: Int? { get }
    var liquidPositions: UnsafeMutableRawPointer? { get }
    var liquidVelocities: UnsafeMutableRawPointer? { get }
    var liquidColors: UnsafeMutableRawPointer? { get }
    
    var circleBodyCount: Int? { get }
    var circleBodiesPositions: UnsafeMutableRawPointer? { get }
    var circleBodiesColors: UnsafeMutableRawPointer? { get }
    var circleBodiesRadii: UnsafeMutableRawPointer? { get }
    
    var cameraX: Float { get }
    var cameraY: Float { get }
    
    var backgroundAnchorPositions: UnsafeMutableRawPointer? { get }
    var backgroundAnchorRadii: UnsafeMutableRawPointer? { get }
    var backgroundAnchorColors: UnsafeMutableRawPointer? { get }
    var backgroundAnchorPointCount: Int? { get }
}

extension RenderDataSource {
    var cameraX: Float { 0 }
    var cameraY: Float { 0 }
}
