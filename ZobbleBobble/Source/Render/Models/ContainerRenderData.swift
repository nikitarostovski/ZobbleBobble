//
//  GunRenderData.swift
//  ZobbleBobble
//
//  Created by Rost on 18.08.2023.
//

import Foundation

struct ContainerRenderData {
    let originPointer: UnsafeMutableRawPointer
    let sizePointer: UnsafeMutableRawPointer
    var materialsPointer: UnsafeMutableRawPointer
    var materialCount: Int
}
