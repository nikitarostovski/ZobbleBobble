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
}
