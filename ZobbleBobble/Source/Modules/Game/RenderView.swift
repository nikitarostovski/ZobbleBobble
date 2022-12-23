//
//  RenderView.swift
//  ZobbleBobble
//
//  Created by Rost on 20.12.2022.
//

import UIKit

//enum RenderData {
//    case polygon(polygon: [CGPoint], color: SIMD4<UInt8>)
//    case circle(position: CGPoint, radius: CGFloat, color: SIMD4<UInt8>)
//    case liquid(count: Int, radius: CGFloat, positions: UnsafeMutableRawPointer, colors: UnsafeMutableRawPointer)
//}

protocol RenderView: UIView {
    func setRenderData(polygonMesh: PolygonMesh?, circleMesh: CircleMesh?, liquidMesh: LiquidMesh?)
    func setUniformData(particleRadius: Float)
}
