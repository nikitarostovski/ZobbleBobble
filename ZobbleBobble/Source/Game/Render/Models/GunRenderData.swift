//
//  GunRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct GunRenderData {
    let positionPointer: UnsafeMutableRawPointer
    let renderCenterPointer: UnsafeMutableRawPointer
    let missleCenterPointer: UnsafeMutableRawPointer
    let radiusPointer: UnsafeMutableRawPointer
    let missleRadiusPointer: UnsafeMutableRawPointer
    var materialsPointer: UnsafeMutableRawPointer
    var materialCount: Int
}
