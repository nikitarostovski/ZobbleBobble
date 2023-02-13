//
//  RenderDataSource.swift
//  ZobbleBobble
//
//  Created by Rost on 29.12.2022.
//

import Foundation

protocol CameraRenderDataSource: AnyObject {
    var cameraX: Float { get }
    var cameraY: Float { get }
    var cameraScale: Float { get }
    var cameraAngle: Float { get }
}

protocol BackgroundRenderDataSource: AnyObject {
    var backgroundAnchorPositions: UnsafeMutableRawPointer? { get }
    var backgroundAnchorRadii: UnsafeMutableRawPointer? { get }
    var backgroundAnchorColors: UnsafeMutableRawPointer? { get }
    var backgroundAnchorPointCount: Int? { get }
}

protocol StarsRenderDataSource: AnyObject {
    var starPositions: [UnsafeMutableRawPointer] { get }
    var starRadii: [UnsafeMutableRawPointer] { get }
    var starMainColors: [UnsafeMutableRawPointer] { get }
    var starMaterials: [UnsafeMutableRawPointer] { get }
    var starMaterialCounts: [Int] { get }
    var starsHasChanges: Bool { get }
}

protocol ObjectRenderDataSource: AnyObject {
    var particleRadius: Float { get }
    
    var liquidFadeModifier: Float { get }
    var liquidCount: Int? { get }
    var liquidPositions: UnsafeMutableRawPointer? { get }
    var liquidVelocities: UnsafeMutableRawPointer? { get }
    var liquidColors: UnsafeMutableRawPointer? { get }
    
    var staticLiquidCount: Int? { get }
    var staticLiquidPositions: UnsafeMutableRawPointer? { get }
    var staticLiquidVelocities: UnsafeMutableRawPointer? { get }
    var staticLiquidColors: UnsafeMutableRawPointer? { get }
    
    var circleBodyCount: Int? { get }
    var circleBodiesPositions: UnsafeMutableRawPointer? { get }
    var circleBodiesColors: UnsafeMutableRawPointer? { get }
    var circleBodiesRadii: UnsafeMutableRawPointer? { get }
}
